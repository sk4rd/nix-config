#!/usr/bin/env python3
"""Build and smoke-test the real desktop Neovim config without activation."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[3]
FLAKE = json.dumps('path:' + str(REPO))
BASE = f'''let f = builtins.getFlake {FLAKE};
  c = f.nixosConfigurations.desktop.config.home-manager.users.miko;
  p = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in '''


def nix(*args):
    return subprocess.check_output(['nix', *args], cwd=REPO, text=True)


def main():
    runtime_expr = BASE + '''p.linkFarm "neovim-smoke-runtime" [
      { name = "bin"; path = "${c.programs.neovim.finalPackage}/bin"; }
      { name = "pack"; path = c.xdg.dataFile."nvim/site/pack/hm".source; }
    ]'''
    runtime = Path(json.loads(nix('build', '--impure', '--no-link', '--json', '--expr', runtime_expr))[0]['outputs']['out'])
    config_expr = BASE + '''{
      init = c.xdg.configFile."nvim/init.lua".text;
      palette = c.xdg.configFile."nvim/lua/neon-flux-palette.lua".text;
      settings = c.xdg.configFile."nvim/lua/neon-flux-settings.lua".text;
      theme = builtins.readFile c.xdg.configFile."nvim/colors/neon-flux.lua".source;
    }'''
    generated = json.loads(nix('eval', '--impure', '--json', '--expr', config_expr))
    scratch = Path(os.environ.get('TMPDIR', str(Path.home() / '.cache')))
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='neovim-test-', dir=scratch) as directory:
        root = Path(directory)
        config = root / 'config/nvim'
        (config / 'lua').mkdir(parents=True)
        (config / 'colors').mkdir()
        for name, key in [('init.lua', 'init'), ('lua/neon-flux-palette.lua', 'palette'),
                          ('lua/neon-flux-settings.lua', 'settings'), ('colors/neon-flux.lua', 'theme')]:
            (config / name).write_text(generated[key])
        # Override only the fixture path: a user override must never touch real notes.
        (config / 'lua/neon-flux-settings.lua').write_text('return { notesDirectory = "~/Documents/notes" }\n')
        notes = root / 'home/Documents/notes'
        notes.mkdir(parents=True)
        (notes / 'tasks.org').write_text('* TODO Keep existing notes\n')
        (notes / 'inbox.md').write_text('# Existing inbox\n\nKeep this text.\n')
        project = root / 'home/project'
        project.mkdir(parents=True)
        subprocess.run(['git', 'init', '-q', str(project)], check=True)
        (project / 'default.nix').write_text('{answer=42;}\n')
        subprocess.run(['git', '-C', str(project), 'add', 'default.nix'], check=True)
        subprocess.run(['git', '-C', str(project), '-c', 'user.name=Test', '-c',
                        'user.email=test@example.invalid', '-c', 'commit.gpgsign=false',
                        'commit', '-qm', 'Fixture'], check=True)
        pack = root / 'data/nvim/site/pack/hm'
        pack.parent.mkdir(parents=True)
        pack.symlink_to(runtime / 'pack')
        env = os.environ | {'HOME': str(root / 'home')}
        for kind in ['CONFIG', 'DATA', 'STATE', 'CACHE']:
            env['XDG_' + kind + '_HOME'] = str(root / kind.lower())
        env.pop('NVIM_APPNAME', None)
        subprocess.run([str(runtime / 'bin/nvim'), '--headless',
                        '+luafile ' + str(Path(__file__).with_name('test.lua'))],
                       env=env, check=True, timeout=45)


if __name__ == '__main__':
    main()
