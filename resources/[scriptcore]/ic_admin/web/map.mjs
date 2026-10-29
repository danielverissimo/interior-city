// Independent map viewport; uses the locally admitted atlas and an explicit GTA CRS.
export function project(x,y,crs={centerX:117.3,centerY:172.8,scaleX:.02072,scaleY:.0205}) {
    const point={x:(Number(x)*crs.scaleX+crs.centerX)/256,y:(-Number(y)*crs.scaleY+crs.centerY)/256};
    return Number.isFinite(point.x)&&Number.isFinite(point.y)&&point.x>=0&&point.x<=1&&point.y>=0&&point.y<=1 ? point : null;
}
export function createMap() {
    let host,world,markers,select,observer,players=[],scale=1,offset={x:0,y:0},drag=null,crs;
    let cleanup=()=>{};
    function paint() {
        if(!host)return;
        const size=Math.min(host.clientWidth,host.clientHeight)*scale;
        world.style.width=`${size}px`;world.style.height=`${size}px`;
        world.style.transform=`translate(${(host.clientWidth-size)/2+offset.x}px,${(host.clientHeight-size)/2+offset.y}px)`;
        const fragment=document.createDocumentFragment();
        for(const player of players){
            const coords=player.coords||player.position;
            if(!coords)continue;
            const point=project(coords.x??coords[0],coords.y??coords[1],crs);if(!point)continue;
            const button=document.createElement('button');button.className='atlas-player';button.dataset.player=String(player.id);
            button.textContent=`#${player.id} ${player.name}`;button.title=`${player.name} · ${Number(coords.x??coords[0]).toFixed(1)}, ${Number(coords.y??coords[1]).toFixed(1)}`;
            button.style.left=`${point.x*100}%`;button.style.top=`${point.y*100}%`;fragment.append(button);
        }
        markers.replaceChildren(fragment);
        host.querySelector('[data-map-scale]').textContent=`${Math.round(scale*100)}%`;
    }
    function zoom(next,clientX,clientY){
        const old=scale;scale=Math.max(.75,Math.min(12,next));
        if(clientX!==undefined){
            const rect=host.getBoundingClientRect(),x=clientX-rect.left-host.clientWidth/2,y=clientY-rect.top-host.clientHeight/2;
            offset.x=x-(x-offset.x)*scale/old;offset.y=y-(y-offset.y)*scale/old;
        }
        paint();
    }
    function setPlayers(value){
        players=value;
        if(select){const selected=select.value;select.replaceChildren(new Option('Localizar jogador…',''),...players.map(p=>new Option(`#${p.id} ${p.name}`,String(p.id))));select.value=selected;}
        paint();
    }
    function mount(element,value,options={}){
        cleanup();host=element;crs=options.crs;
        host.className='atlas';host.tabIndex=0;host.setAttribute('aria-label','Mapa GTA. Arraste para navegar; use mais e menos para zoom e Home para centralizar.');
        host.innerHTML='<div class="atlas-world"><img class="atlas-image" alt="Mapa geográfico de Los Santos e Blaine County" draggable="false"><div class="atlas-markers"></div></div><div class="atlas-controls"><button type="button" data-map-in aria-label="Ampliar mapa">+</button><button type="button" data-map-out aria-label="Reduzir mapa">−</button><button type="button" data-map-reset>Centralizar</button><select aria-label="Localizar jogador"></select><output data-map-scale></output></div><div class="atlas-hint">N ↑ · arraste para navegar · clique no jogador para ações</div><p class="atlas-error" hidden>Mapa indisponível. Verifique a instalação dos assets desta release.</p>';
        world=host.querySelector('.atlas-world');markers=host.querySelector('.atlas-markers');select=host.querySelector('select');
        const image=host.querySelector('img');image.src='assets/map.png';image.onerror=()=>{if(element.isConnected)element.querySelector('.atlas-error').hidden=false;};
        host.querySelector('[data-map-in]').onclick=()=>zoom(scale*1.4);
        host.querySelector('[data-map-out]').onclick=()=>zoom(scale/1.4);
        host.querySelector('[data-map-reset]').onclick=()=>{scale=1;offset={x:0,y:0};paint();};
        select.onchange=()=>{
            const player=players.find(p=>String(p.id)===select.value),c=player?.coords||player?.position;
            const point=c&&project(c.x??c[0],c.y??c[1],crs);if(!point)return;
            scale=Math.max(scale,3);const size=Math.min(host.clientWidth,host.clientHeight)*scale;
            offset={x:(.5-point.x)*size,y:(.5-point.y)*size};paint();
        };
        const wheel=event=>{if(event.target.closest('.atlas-controls'))return;event.preventDefault();zoom(scale*(event.deltaY<0?1.15:1/1.15),event.clientX,event.clientY);};
        const down=event=>{if(event.button!==0||event.target.closest('.atlas-controls,.atlas-player'))return;drag={x:event.clientX,y:event.clientY,offset:{...offset},moved:false};host.setPointerCapture(event.pointerId);};
        const move=event=>{if(!drag)return;const x=event.clientX-drag.x,y=event.clientY-drag.y;if(Math.hypot(x,y)>4)drag.moved=true;offset={x:drag.offset.x+x,y:drag.offset.y+y};paint();};
        let suppress=false;
        const up=()=>{suppress=!!drag?.moved;drag=null;};
        const click=event=>{if(suppress){event.preventDefault();event.stopPropagation();suppress=false;}};
        const key=event=>{
            if(event.target.closest('.atlas-controls'))return;
            if(['+','=','-','Home','ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(event.key))event.preventDefault();
            if(event.key==='+'||event.key==='=')zoom(scale*1.3);else if(event.key==='-')zoom(scale/1.3);
            else if(event.key==='Home'){offset={x:0,y:0};scale=1;paint();}
            else {const delta={ArrowLeft:[60,0],ArrowRight:[-60,0],ArrowUp:[0,60],ArrowDown:[0,-60]}[event.key];if(delta){offset.x+=delta[0];offset.y+=delta[1];paint();}}
        };
        host.addEventListener('wheel',wheel,{passive:false});host.addEventListener('pointerdown',down);host.addEventListener('pointermove',move);host.addEventListener('pointerup',up);host.addEventListener('pointercancel',up);host.addEventListener('click',click,true);host.addEventListener('keydown',key);
        observer=new ResizeObserver(paint);observer.observe(host);
        const current=host;
        cleanup=()=>{observer?.disconnect();for(const [event,fn] of [['wheel',wheel],['pointerdown',down],['pointermove',move],['pointerup',up],['pointercancel',up],['keydown',key]])current.removeEventListener(event,fn);current.removeEventListener('click',click,true);host=null;};
        setPlayers(value);
    }
    return {mount,setPlayers,destroy:()=>cleanup()};
}
