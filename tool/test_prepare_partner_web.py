import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class PreparePartnerWebTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / 'app'
        (self.repo / 'lib').mkdir(parents=True)
        (self.repo / 'test').mkdir()
        (self.repo / 'tool').mkdir()
        self.canonical_lock = 'original-locked-dependencies\n'
        (self.repo / 'pubspec.yaml').write_text('name: go_partner\n')
        (self.repo / 'pubspec.lock').write_text(self.canonical_lock)
        (self.repo / 'analysis_options.yaml').write_text('analyzer: {}\n')
        (self.repo / 'lib/main.dart').write_text('void main() {}\n')
        shutil.copyfile(
            Path(__file__).with_name('prepare_partner_web.sh'),
            self.repo / 'tool/prepare_partner_web.sh',
        )
        self.git('init', '-q')
        self.git('config', 'user.name', 'Preparation Test')
        self.git('config', 'user.email', 'preparation@example.invalid')
        self.git('add', '.')
        self.git('commit', '-qm', 'Fixture')
        self.calls = self.root / 'calls.jsonl'
        self.fake_flutter = self.root / 'flutter'
        self.fake_flutter.write_text('''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

args = sys.argv[1:]
with Path(os.environ['PREPARATION_CALLS']).open('a') as calls:
    calls.write(json.dumps(args) + '\\n')
if args[0] == 'create':
    Path('pubspec.lock').write_text('template-sdk-dependencies\\n')
    Path('analysis_options.yaml').write_text('template-analysis-policy\\n')
    test = Path('test/widget_test.dart')
    if not test.exists():
        test.write_text('new generated counter test\\n')
    change = os.environ.get('PREPARATION_ALTER_SOURCE')
    if change:
        Path(change).write_text('unexpected generated application change\\n')
elif args[:2] == ['pub', 'get']:
    if Path('pubspec.lock').read_text() != 'original-locked-dependencies\\n':
        sys.exit(99)
    if args != ['pub', 'get', '--enforce-lockfile']:
        sys.exit(98)
    Path('analysis_options.yaml').write_text('pub-migrated-analysis-policy\\n')
    if os.environ.get('PREPARATION_PUB_FAILURE'):
        sys.exit(42)
else:
    sys.exit(97)
''')
        self.fake_flutter.chmod(0o755)

    def git(self, *args):
        return subprocess.run(
            ['git', *args], cwd=self.repo, check=True, capture_output=True, text=True,
        )

    def prepare(self, **extra):
        environment = os.environ.copy()
        environment.update(
            PARTNER_FLUTTER_BIN=str(self.fake_flutter),
            PREPARATION_CALLS=str(self.calls),
            **extra,
        )
        return subprocess.run(
            ['bash', 'tool/prepare_partner_web.sh'], cwd=self.repo,
            env=environment, capture_output=True, text=True,
        )

    def recorded_calls(self):
        return [json.loads(row) for row in self.calls.read_text().splitlines()]

    def test_restores_lock_and_removes_only_the_new_template_test(self):
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.recorded_calls(), [
            ['create', '.', '--platforms', 'web', '--no-pub'],
            ['pub', 'get', '--enforce-lockfile'],
        ])
        self.assertEqual((self.repo / 'pubspec.lock').read_text(), self.canonical_lock)
        self.assertEqual((self.repo / 'analysis_options.yaml').read_text(), 'analyzer: {}\n')
        self.assertFalse((self.repo / 'test/widget_test.dart').exists())
        self.assertEqual(self.git('status', '--porcelain').stdout, '')

    def test_preserves_an_existing_tracked_widget_test(self):
        test = self.repo / 'test/widget_test.dart'
        test.write_text('existing application test\n')
        self.git('add', str(test))
        self.git('commit', '-qm', 'Existing test')
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(test.read_text(), 'existing application test\n')

    def test_preserves_an_existing_untracked_widget_test(self):
        test = self.repo / 'test/widget_test.dart'
        test.write_text('untracked developer test\n')
        result = self.prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(test.read_text(), 'untracked developer test\n')

    def test_rejects_generated_application_source_changes_before_pub(self):
        result = self.prepare(PREPARATION_ALTER_SOURCE='lib/main.dart')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('changed application source', result.stderr)
        self.assertEqual(len(self.recorded_calls()), 1)

    def test_rejects_generated_manifest_changes_before_pub(self):
        result = self.prepare(PREPARATION_ALTER_SOURCE='pubspec.yaml')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('changed application source', result.stderr)
        self.assertEqual(len(self.recorded_calls()), 1)

    def test_propagates_lockfile_enforcement_failure(self):
        result = self.prepare(PREPARATION_PUB_FAILURE='1')
        self.assertEqual(result.returncode, 42)
        self.assertEqual(len(self.recorded_calls()), 2)

    def test_does_not_discard_preexisting_dependency_changes(self):
        lock = self.repo / 'pubspec.lock'
        lock.write_text('developer dependency edits\n')
        result = self.prepare()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.calls.exists())
        self.assertEqual(lock.read_text(), 'developer dependency edits\n')


if __name__ == '__main__':
    unittest.main()
