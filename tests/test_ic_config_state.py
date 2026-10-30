"""State preparation validates everything before writing a private new snapshot."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('ic_config_state', ROOT / 'scripts/ic-config-state.py')
state = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(state)


class ConfigStateTests(unittest.TestCase):
    def fixture(self, root):
        for relative, kind in state.FILES.items():
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(kind()))

    def test_plan_has_no_writes_and_all_real_paths_exist(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp).resolve() / 'snapshot'
            result = state.prepare(ROOT, output)
            self.assertEqual(result['files'], 28)
            self.assertFalse(result['applied'])
            self.assertFalse(output.exists())

    def test_snapshot_copies_effective_state_and_overlay_without_hardlinks(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, output = root / 'source', root / 'snapshot'
            self.fixture(source)
            key = 'resources/[vrp]/vrp/cfg/groups.json'
            effective = root / 'effective-groups.json'
            effective.write_text('{"groups":[{"name":"dono"}]}')
            source_map = root / 'source-map.json'
            source_map.write_text(json.dumps({key: str(effective)}))
            result = state.prepare(source, output, source_map, apply=True, writers_stopped=True)
            self.assertTrue(result['applied'])
            self.assertEqual((output / key).read_bytes(), effective.read_bytes())
            self.assertNotEqual((output / key).stat().st_ino, effective.stat().st_ino)
            self.assertEqual((output / key).stat().st_mode & 0o777, 0o600)
            self.assertEqual(output.stat().st_mode & 0o777, 0o700)
            overlay = (output / 'compose.ic-config.yaml').read_text()
            self.assertEqual(overlay.count('create_host_path: false'), 28)
            self.assertIn(str(output / key), overlay)
            self.assertTrue(state.verify(output)['verified'])
            (output / key).write_text('{}')
            with self.assertRaises(state.StateError):
                state.verify(output)

    def test_refuses_running_writers_overwrite_and_symbolic_links(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, output = root / 'source', root / 'snapshot'
            self.fixture(source)
            with self.assertRaises(state.StateError):
                state.prepare(source, output, apply=True)
            self.assertFalse(output.exists())
            output.mkdir()
            with self.assertRaises(state.StateError):
                state.prepare(source, output, apply=True, writers_stopped=True)
            output.rmdir()
            key = next(iter(state.FILES))
            target = source / key
            real = root / 'real.json'
            target.rename(real)
            target.symlink_to(real)
            with self.assertRaises(state.StateError):
                state.prepare(source, output, apply=True, writers_stopped=True)
            self.assertFalse(output.exists())

    def test_invalid_late_source_never_leaves_partial_snapshot(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            source, output = root / 'source', root / 'snapshot'
            self.fixture(source)
            last = list(state.FILES)[-1]
            (source / last).write_text('{"secret":"do-not-print",')
            with self.assertRaises(state.StateError) as error:
                state.prepare(source, output, apply=True, writers_stopped=True)
            self.assertNotIn('do-not-print', str(error.exception))
            self.assertFalse(output.exists())


if __name__ == '__main__':
    unittest.main()
