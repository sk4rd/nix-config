import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

HERE = Path(__file__).parent


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, HERE / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


template = load("windows-gaming-template.py", "template")
validator = load("../modules/features/virtualisation/validate-windows-gaming.py", "validator")


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.gpu = "0000:09:00.0"
        self.audio = "0000:09:00.1"
        self.root = ET.fromstring(template.generate(self.gpu, self.audio, Path("/images/windows.qcow2")))

    def check(self):
        validator.validate(ET.tostring(self.root), self.gpu, self.audio)

    def test_valid_template(self):
        self.check()

    def test_missing_audio(self):
        self.root.find("devices").remove(self.root.findall("./devices/hostdev")[1])
        with self.assertRaisesRegex(ValueError, "managed PCI hostdevs missing"):
            self.check()

    def test_unmanaged_gpu(self):
        self.root.findall("./devices/hostdev")[0].set("managed", "no")
        with self.assertRaisesRegex(ValueError, "managed PCI hostdevs missing"):
            self.check()


if __name__ == "__main__":
    unittest.main()
