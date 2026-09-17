#!/usr/bin/env python3
"""Check immutable primary source pins without rewriting any source."""
import argparse,json,pathlib,subprocess,sys
root=pathlib.Path(__file__).resolve().parents[1]
# Source exports carry a file manifest instead of Git administrative data.
if not (root/'.git').exists() and (root/'source-manifest.json').exists():
 import hashlib
 manifest=json.loads((root/'source-manifest.json').read_text())
 for name,entry in manifest['files'].items():
  path=root/name
  if 'link' in entry:
   if not path.is_symlink() or str(path.readlink())!=entry['link']:raise SystemExit('Source link mismatch: '+name)
  elif not path.is_file() or hashlib.file_digest(path.open('rb'),'sha256').hexdigest()!=entry['sha256']:raise SystemExit('Source content mismatch: '+name)
 print('PASS: source archive manifest '+manifest['app_commit'])
 sys.exit(0)
lock=json.loads((root/'sources.lock.json').read_text())
def git(path,*args):return subprocess.check_output(['git','-C',str(path),*args],text=True).strip()
p=argparse.ArgumentParser();p.add_argument('--component',choices=lock['components'],action='append');args=p.parse_args()
try:
 for name in args.component or lock['components']:
  spec=lock['components'][name];path=root/spec['path']
  if not path.exists() or git(path,'rev-parse','HEAD')!=spec['commit']:raise ValueError(f'{name}: missing or wrong source commit; run scripts/bootstrap-sources.sh')
  if git(path,'status','--porcelain','--untracked-files=no'):raise ValueError(f'{name}: tracked source has local changes')
  entry=git(root,'ls-files','--stage',spec['path']).split()
  if len(entry)<2 or entry[0]!='160000' or entry[1]!=spec['commit']:raise ValueError(f'{name}: app gitlink and lock disagree')
  if name=='goldeneye':
   ge=path/'lib/ge'
   if git(ge,'rev-parse','HEAD')!='c4356466796c697dfd298010b9bed261f9ed8c6a':raise ValueError('Reference header pin mismatch')
   if git(ge,'status','--porcelain','--untracked-files=no'):raise ValueError('Reference headers have tracked changes')
  if name.startswith('rt64-'):
   for line in git(path,'submodule','status','--recursive').splitlines():
    if line.startswith(('-','+','U')):raise ValueError(f'{name}: missing/mismatched nested source: {line}')
   platform=name.split('-')[1];plume=path/'src/contrib/plume'
   if git(plume,'rev-parse','HEAD')!=lock['plume'][platform]['commit']:raise ValueError('Plume pin mismatch')
   if git(plume,'status','--porcelain','--untracked-files=no'):raise ValueError('Plume has tracked changes')
  print(f'PASS: {name} {spec["commit"]}')
except (subprocess.CalledProcessError,ValueError) as e:
 print(f'Source check failed: {e}',file=sys.stderr);sys.exit(1)
