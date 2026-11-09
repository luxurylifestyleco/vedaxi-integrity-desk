import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const dir=path.dirname(fileURLToPath(import.meta.url));
const manifest=JSON.parse(await fs.readFile(path.join(dir,'manifest.json'),'utf8'));
const report=[];
for(let start=0;start<manifest.length;start+=4){
 await Promise.all(manifest.slice(start,start+4).map(async item=>{
  const target=path.join(dir,item.file);await fs.mkdir(path.dirname(target),{recursive:true});
  let bytes;try{bytes=await fs.readFile(target);}catch{const r=await fetch(item.url);if(!r.ok)throw Error(item.file+': HTTP '+r.status);bytes=Buffer.from(await r.arrayBuffer());await fs.writeFile(target,bytes);}
  if(bytes.subarray(0,8).toString('hex')!=='89504e470d0a1a0a')throw Error('Invalid PNG: '+item.file);
  report.push({file:item.file,job_id:item.job_id,bytes:bytes.length,width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
 }));
}
report.sort((a,b)=>a.file.localeCompare(b.file));
await fs.writeFile(path.join(dir,'verified-downloads.json'),JSON.stringify(report,null,2));
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const html='<!doctype html><meta charset="utf-8"><title>Elastic Web generated photos</title><style>body{font:16px Arial;background:#faf8f3;color:#111;padding:30px}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:20px}article{border:1px solid #c8a15a;padding:12px}img{width:100%;height:220px;object-fit:contain}p{overflow-wrap:anywhere}a{color:#624d24}</style><h1>Generated photos</h1><p>28 original generated PNGs. Superseded images are labelled by folder. Retailer likeness is superseded by the later portrait PDF. All assets are references until storyboard approval.</p><main>'+report.map(r=>'<article><a href="'+escape(r.file)+'" download><img loading="lazy" src="'+escape(r.file)+'"></a><p>'+escape(r.file)+'</p><small>'+r.width+' × '+r.height+' · '+Math.round(r.bytes/1024)+' KB</small></article>').join('')+'</main>';
await fs.writeFile(path.join(dir,'index.html'),html);
console.log(JSON.stringify({downloaded:report.length,bytes:report.reduce((n,r)=>n+r.bytes,0),allPngSignaturesValid:true,folder:dir}));
