(() => {
  'use strict';
  const panel = document.createElement('section');
  panel.id='lockpick-game'; panel.hidden=true;
  panel.innerHTML='<p>ARROMBAR PORTA-MALAS</p><canvas width="220" height="220"></canvas><p>APERTE <b>E</b> OU <b>I</b> NA MARCA BRANCA</p><small>3 acertos · ESC para cancelar</small>';
  document.body.appendChild(panel);
  const canvas=panel.querySelector('canvas'), ctx=canvas.getContext('2d');
  let game=null, frame=0;
  function close() { game=null; cancelAnimationFrame(frame); panel.hidden=true; }
  function finish(success) {
    if(!game) return;
    const token=game.token; close();
    fetch(`https://${GetParentResourceName()}/lockpickResult`, {
      method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({token,success:success===true})
    }).catch(()=>{});
  }
  function round(now) {
    game.roundStart=now;
    game.target=70+Math.random()*170;
    game.width=35+Math.random()*20;
    game.angle=0;
  }
  function animate(now) {
    if(!game) return;
    game.angle=(now-game.roundStart)*166.6667*game.speed/1000;
    if(game.angle>=360 || now-game.started>=20000) { finish(false); return; }
    const radians=degree=>(degree-90)*Math.PI/180;
    ctx.clearRect(0,0,220,220);
    ctx.lineWidth=13; ctx.strokeStyle='#ffffff33'; ctx.beginPath(); ctx.arc(110,110,82,0,Math.PI*2); ctx.stroke();
    ctx.strokeStyle='#ffffff'; ctx.beginPath(); ctx.arc(110,110,82,radians(game.target),radians(game.target+game.width)); ctx.stroke();
    ctx.lineWidth=20; ctx.strokeStyle='#d23d56'; ctx.beginPath(); ctx.arc(110,110,82,radians(game.angle-5),radians(game.angle)); ctx.stroke();
    ctx.fillStyle='#ffffff'; ctx.font='bold 27px Arial'; ctx.textAlign='center'; ctx.fillText(`${game.hits}/3`,110,119);
    frame=requestAnimationFrame(animate);
  }
  window.addEventListener('message', ({data})=>{
    if(data?.action==='lockpickOpen') {
      close();
      const now=performance.now(), speed=Number(data.speed);
      game={token:data.token,hits:0,started:now,speed:Number.isFinite(speed)&&speed>0?speed:1.5};
      round(now); panel.hidden=false; frame=requestAnimationFrame(animate);
    } else if(data?.action==='lockpickClose' && game?.token===data.token) close();
  });
  document.addEventListener('keydown', event=>{
    if(!game || event.repeat) return;
    if(event.code==='Escape' || event.code==='Backspace') { event.preventDefault(); finish(false); return; }
    if(event.code!=='KeyE' && event.code!=='KeyI') return;
    event.preventDefault();
    game.angle=(performance.now()-game.roundStart)*166.6667*game.speed/1000;
    if(game.angle<game.target || game.angle>game.target+game.width) { finish(false); return; }
    game.hits++;
    if(game.hits===3) finish(true); else round(performance.now());
  });
})();
