(() => {
  const box=document.createElement('div');
  box.id='diamond-wallet-hud'; box.hidden=true;
  box.style.cssText='position:fixed;z-index:10;pointer-events:none;display:flex;align-items:center;gap:8px;padding:7px 11px;border-radius:5px;border:1px solid #d9b77a66;background:#101319d9;color:#e7cb91;font:700 12px Arial,sans-serif;';
  box.innerHTML='<span aria-hidden="true" style="font-size:20px">◆</span><span data-balance>—</span><span style="font-size:10px;color:#ddd;font-weight:400">DIAMANTES</span>';
  document.body.appendChild(box);
  let balance=null,open=true,scheduled=false;
  function render() {
    const microphone=document.querySelector('#root svg[viewBox="0 0 19 20"], #root svg[viewBox="0 0 26 26"]');
    const rect=microphone?.parentElement?.getBoundingClientRect();
    const visible=open && balance!==null && rect && rect.width>0 && rect.height>0;
    box.hidden=!visible; box.style.display=visible?'flex':'none';
    if(visible) {
      box.style.top=`${rect.bottom+8}px`;box.style.right=`${Math.max(12,window.innerWidth-rect.right)}px`;
      box.querySelector('[data-balance]').textContent=balance.toLocaleString('pt-BR');
    }
  }
  function schedule(){if(scheduled)return;scheduled=true;requestAnimationFrame(()=>{scheduled=false;render()});}
  window.addEventListener('message',({data})=>{
    if(data?.action==='diamondWallet') {
      balance=data.data?.ok && Number.isFinite(data.data.balance) ? Math.max(0,Math.floor(data.data.balance)):null;
    } else if(data?.action==='open')open=true;
    else if(data?.action==='close')open=false;
    else return;
    schedule();
  });
  const root=document.querySelector('#root');
  if(root)new MutationObserver(schedule).observe(root,{childList:true,subtree:true,attributes:true});
  window.addEventListener('resize',schedule);schedule();
})();
