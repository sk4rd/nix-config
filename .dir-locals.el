((nil . ((compile-command . "just check")))
 (nix-mode
  . ((eglot-workspace-configuration
      . (:nixd
         (:nixpkgs
          (:expr "import (builtins.getFlake (toString ./.)).inputs.nixpkgs { }")
          :formatting (:command ["nixfmt"])
          :options
          (:nixos
           (:expr "(builtins.getFlake (toString ./.)).nixosConfigurations.desktop.options")
           :home-manager
           (:expr "(builtins.getFlake (toString ./.)).nixosConfigurations.desktop.options.home-manager.users.type.getSubOptions []"))))))))
