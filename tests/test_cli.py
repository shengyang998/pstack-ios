import contextlib
import io
import plistlib
import runpy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SKILL = Path(__file__).resolve().parents[1] / "skills" / "pstack-ios"
CLI = SKILL / "scripts" / "pstack-ios"
api = runpy.run_path(str(CLI))


class CLITests(unittest.TestCase):
    def cli(self, *args, cwd):
        return subprocess.run([sys.executable, str(CLI), *args], cwd=cwd,
                              capture_output=True, text=True)

    def test_new_app_has_renamed_scheme_tests_and_bundle(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / "Demo app"
            args = ["new", "--name", "FieldNotes", "--bundle-id", "org.example.field", "--output", str(output)]
            self.assertEqual(self.cli(*args, cwd=folder).returncode, 0)
            proj = output / "FieldNotes.xcodeproj"
            self.assertTrue((proj / "xcshareddata/xcschemes/FieldNotes.xcscheme").is_file())
            self.assertIn("org.example.field", (proj / "project.pbxproj").read_text())
            test = output / "Tests/CounterTests.swift"
            self.assertIn("import FieldNotes", test.read_text())
            test.write_text("existing user work")
            self.assertNotEqual(self.cli(*args, cwd=folder).returncode, 0)
            self.assertEqual(test.read_text(), "existing user work")

    def test_ambiguous_containers_are_reported_before_xcode_runs(self):
        with tempfile.TemporaryDirectory() as folder:
            (Path(folder) / "A.xcodeproj").mkdir()
            (Path(folder) / "A.xcworkspace").mkdir()
            result = self.cli("inspect", cwd=folder)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("A.xcodeproj", result.stderr)
            self.assertIn("A.xcworkspace", result.stderr)

    def test_package_build_uses_package_directory(self):
        with tempfile.TemporaryDirectory() as folder:
            manifest = Path(folder).resolve() / "Package.swift"
            manifest.touch()
            for selected in (manifest.parent, manifest):
                self.assertEqual(api["project_context"](selected), (manifest.parent, []))

    def test_mixed_package_explicitly_selects_native_swiftpm_workspace(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder).resolve()
            manifest = root / "Package.swift"
            manifest.touch()
            (root / "Neighbor.xcodeproj").mkdir()
            cwd, options = api["project_context"](manifest)
            self.assertEqual(cwd, root)
            self.assertEqual(options, ["-workspace", root / ".swiftpm/xcode/package.xcworkspace"])
            self.assertTrue(options[1].is_dir())

    def test_only_available_ios_devices_are_selectable(self):
        devices = {"devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [
                {"udid": "PHONE", "isAvailable": True}, {"udid": "OLD", "isAvailable": False}],
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-2": [{"udid": "TV", "isAvailable": True}]}}
        with mock.patch.dict(api["simulators"].__globals__, json_call=lambda *args: devices):
            self.assertEqual(api["device_for"]("phone")["udid"], "PHONE")
            with self.assertRaises(ValueError):
                api["device_for"]("TV")

    def test_failed_or_empty_result_is_not_success(self):
        for verdict, passed, failed, ok in [
            ("Passed", 2, 0, True), ("Passed", 0, 0, False), ("Skipped", 0, 0, False),
            ("Failed", 2, 1, False), ("Failed", 2, 0, False)]:
            with self.subTest(verdict=verdict, passed=passed, failed=failed):
                record = {"result": verdict, "passedTests": passed, "failedTests": failed}
                with mock.patch.dict(api["results"].__globals__, json_call=lambda *args: record):
                    with contextlib.redirect_stdout(io.StringIO()):
                        if ok:
                            api["results"]("result.xcresult")
                        else:
                            with self.assertRaises(ValueError):
                                api["results"]("result.xcresult")

    def test_local_export_rejects_upload_before_xcode_runs(self):
        with tempfile.TemporaryDirectory() as folder:
            archive = Path(folder) / "App.xcarchive"
            archive.mkdir()
            (archive / "Info.plist").write_bytes(plistlib.dumps({}))
            options = Path(folder) / "ExportOptions.plist"
            options.write_bytes(plistlib.dumps({"destination": "upload"}))
            result = self.cli("export", "--archive", str(archive), "--options", str(options), cwd=folder)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("destination 'export'", result.stderr)
            self.assertNotIn("+ xcodebuild", result.stderr)


if __name__ == "__main__":
    unittest.main()
