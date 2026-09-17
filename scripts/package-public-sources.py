#!/usr/bin/env python3
"""Export the app and exact public build inputs; never copy working directories."""
import gzip,hashlib,json,pathlib,subprocess,tarfile,tempfile
root=pathlib.Path(__file__).resolve().parents[1]
subprocess.run(['python3',str(root/'scripts/check-sources.py')],check=True)
if subprocess.check_output(['git','-C',str(root),'status','--porcelain','--untracked-files=no'],text=True).strip():raise SystemExit('Commit tracked changes before exporting source.')
lock=json.loads((root/'sources.lock.json').read_text());revision=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
def export(repo,dest,paths=()):
 dest.mkdir(parents=True,exist_ok=True)
 p=subprocess.Popen(['git','-C',str(repo),'archive','HEAD',*paths],stdout=subprocess.PIPE)
 subprocess.run(['tar','-x','-C',str(dest)],stdin=p.stdout,check=True);p.stdout.close()
 if p.wait():raise SystemExit('git archive failed')
def nested(repo,dest):
 export(repo,dest)
 for record in subprocess.check_output(['git','-C',str(repo),'ls-tree','-rz','HEAD']).split(b'\0'):
  if record.startswith(b'160000'):
   rel=record.split(b'\t')[1].decode();nested(repo/rel,dest/rel)
with tempfile.TemporaryDirectory(prefix='goldenpad-source-') as tmp:
 stage=pathlib.Path(tmp)/'GoldenPad-source';export(root,stage)
 for name,spec in lock['components'].items():
  repo=root/spec['path'];dest=stage/spec['path']
  if name=='goldeneye':
   export(repo,dest);export(repo/'lib/ge',dest/'lib/ge',('include',))
  else:nested(repo,dest)
 files={}
 for p in sorted(stage.rglob('*')):
  if p.is_symlink():files[str(p.relative_to(stage))]={'link':str(p.readlink())}
  elif p.is_file():
   if p.suffix.lower() in {'.z64','.v64','.n64','.rom','.eep','.sav','.mobileprovision','.p12','.pem','.key'}:raise SystemExit('Disallowed source archive path: '+str(p.relative_to(stage)))
   files[str(p.relative_to(stage))]={'sha256':hashlib.file_digest(p.open('rb'),'sha256').hexdigest()}
 (stage/'source-manifest.json').write_text(json.dumps({'app_commit':revision,'scope':'Public software sources and reference headers. User ROM and generated game code excluded; not a legal corresponding-source certification.','files':files},indent=2)+'\n')
 output=root/'dist'/('GoldenPad-public-sources-'+revision[:12]+'.tar.gz');output.parent.mkdir(exist_ok=True)
 with output.open('wb') as raw,gzip.GzipFile(filename='',mode='wb',fileobj=raw,mtime=0) as gz,tarfile.open(fileobj=gz,mode='w') as tar:
  for p in [stage,*sorted(stage.rglob('*'))]:
   info=tar.gettarinfo(str(p),str(p.relative_to(stage.parent)));info.uid=info.gid=0;info.uname=info.gname='';info.mtime=0
   if info.isfile():
    with p.open('rb') as f:tar.addfile(info,f)
   else:tar.addfile(info)
 digest=hashlib.file_digest(output.open('rb'),'sha256').hexdigest();output.with_suffix(output.suffix+'.sha256').write_text(digest+'  '+output.name+'\n')
 print(output);print(digest);print(len(files),'source files/symlinks')
