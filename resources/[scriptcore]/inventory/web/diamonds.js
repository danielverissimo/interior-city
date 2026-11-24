(() => {
  const wrapper=document.querySelector('#inventory .left-wrapper');
  if(!wrapper)return;
  const card=document.createElement('section');
  card.id='inventory-diamond-wallet';card.setAttribute('aria-label','Carteira de diamantes');
  card.style.cssText='display:flex;align-items:center;gap:12px;padding:12px 16px;margin:10px 0;border:1px solid #d9b77a66;border-radius:8px;background:#131820dd;color:#eee;font:12px Inter,Arial,sans-serif;';
  card.innerHTML='<span data-stack aria-hidden="true" style="font-size:30px;color:#e7cb91">◆</span><div><strong>Diamantes</strong><p data-balance style="margin:5px 0;color:#e7cb91">Carregando carteira…</p><small>Disponíveis para compras na Luxury Motors</small></div>';
  const profile=wrapper.querySelector('.profile-wrapper');
  if(profile)profile.insertAdjacentElement('afterend',card);else wrapper.prepend(card);
  let revision=0;
  function render(wallet){
    const valid=wallet?.ok && Number.isFinite(wallet.balance);
    const balance=valid?Math.max(0,Math.floor(wallet.balance)):0;
    card.querySelector('[data-stack]').hidden=!valid||balance===0;
    card.querySelector('[data-balance]').textContent=valid ? balance ? `${balance.toLocaleString('pt-BR')} diamantes` : 'Você não possui diamantes.' : 'Carteira indisponível';
  }
  window.addEventListener('message',async({data})=>{
    if(data?.route==='DIAMOND_WALLET'){revision++;render(data.payload);return;}
    if(data?.route!=='OPEN_INVENTORY')return;
    const current=++revision;
    try{
      const response=await fetch(`https://${GetParentResourceName()}/DIAMOND_WALLET`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
      const wallet=await response.json();if(current===revision)render(wallet);
    }catch{if(current===revision)render({ok:false});}
  });
})();
