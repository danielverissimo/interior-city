const $=s=>document.querySelector(s), $$=s=>[...document.querySelectorAll(s)];
const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'mg_config_panel';

let module='groups';
let garageTab='points';
let chests=[], garages=[], garageTypes=[], shops=[], craftSetups={benches:[],farm:{}}, clothingShops=[], barbershops=[], tattooShops=[], cloakrooms=[], mapMarkings=[], managedGroups=[], desmanches=[], desmancheSettings={}, safeZones=[], safeZoneSettings={}, safeZoneWhitelist=[], jobsData={jobs:{},extras:{},central:[],npc:[]}, robberiesData={locations:[],setups:{},webhooks:{},settings:{}}, bancoCentralData={name:'Banco Central',settings:{},banks:[]}, joalheriaData={name:'Joalheria',settings:{},rewards:[],displays:[]}, roubocofreData={name:'Roubo a Cofres',settings:{},banks:{}}, residencesData={settings:{},interiors:{},residences:[]}, dealershipData={settings:{},testDrive:{},categories:[],vips:[],vehicles:{}}, mansionsData={mansions:[]}, serverVehicleCatalog={}, dealershipView='dealership', serverVehicleBulkMode=false, serverVehicleBulkSelection=new Set(), serverVehicleVisibleSpawns=[];
let serverItems=[], pickerSelection=new Set(), shopItemDraft={}, pickerContext=null;
let editing=null, pending=null;
let mansionDoorDraft=[];

async function nui(event,data={}){
    try{
        const r=await fetch(`https://${resource}/${event}`,{
            method:'POST',
            headers:{'Content-Type':'application/json'},
            body:JSON.stringify(data)
        });
        return await r.json();
    }catch(e){
        return {ok:false,message:'Falha de comunicação com o resource.'};
    }
}

function esc(v){
    return String(v??'').replace(/[&<>'"]/g,c=>({
        '&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#039;','"':'&quot;'
    }[c]));
}
function enc(v){ return encodeURIComponent(String(v??'')); }
function dec(v){ try{return decodeURIComponent(v)}catch{return v} }
function f(n){return Number(n||0).toFixed(2)}

/* ==========================================================================
   COORDENADAS UNIFICADAS
   Aceita somente: X,Y,Z  ex.: 46.63,-899.06,29.98
   ========================================================================== */
function parsePanelCoordinate(value){
    const parts=String(value??'').trim().split(',').map(v=>v.trim());
    if(parts.length!==3 || parts.some(v=>v===''))return null;

    const nums=parts.map(Number);
    if(nums.some(v=>!Number.isFinite(v)))return null;

    return {x:nums[0],y:nums[1],z:nums[2]};
}

function panelCoordinateText(x,y,z){
    const vals=[x,y,z];
    if(vals.some(v=>v===undefined||v===null||String(v).trim()===''))return '';
    const nums=vals.map(Number);
    if(nums.some(v=>!Number.isFinite(v)))return '';
    return nums.map(v=>String(v)).join(',');
}

function warnInvalidPanelCoordinate(input){
    if(!input || input.dataset.coordWarned==='1')return;
    input.dataset.coordWarned='1';
    toast('Digite uma coordenada correta!','error');
    setTimeout(()=>{ if(input)delete input.dataset.coordWarned; },800);
}

function bindCombinedCoordinateInput(input,xInput,yInput,zInput){
    if(!input||!xInput||!yInput||!zInput)return;

    input._coordSources={x:xInput,y:yInput,z:zInput};

    const syncToSources=()=>{
        const parsed=parsePanelCoordinate(input.value);
        input.classList.toggle('coord-invalid',!!input.value.trim()&&!parsed);
        input.dataset.coordValid=parsed?'1':'0';

        if(parsed){
            xInput.value=parsed.x;
            yInput.value=parsed.y;
            zInput.value=parsed.z;
        }
        return parsed;
    };

    input.addEventListener('input',syncToSources);
    input.addEventListener('change',()=>{
        if(!syncToSources())warnInvalidPanelCoordinate(input);
    });
    input.addEventListener('blur',()=>{
        if(input.value.trim()&&!syncToSources())warnInvalidPanelCoordinate(input);
    });

    syncToSources();
}

function enhanceLabeledCoordinateGroups(scope=document){
    const grids=[
        ...(scope.matches?.('.grid3,.grid4')?[scope]:[]),
        ...scope.querySelectorAll('.grid3,.grid4')
    ];

    grids.forEach(grid=>{
        if(grid.dataset.coordCombined==='1')return;

        const labels=[...grid.children].filter(el=>el.matches?.('label.field'));
        const byAxis={};

        labels.forEach(label=>{
            const span=label.querySelector(':scope > span');
            const input=label.querySelector(':scope > input');
            if(!span||!input)return;
            const axis=span.textContent.trim().toUpperCase();
            if(['X','Y','Z'].includes(axis))byAxis[axis]={label,input};
        });

        if(!byAxis.X||!byAxis.Y||!byAxis.Z)return;

        const x=byAxis.X.input,y=byAxis.Y.input,z=byAxis.Z.input;
        const required=x.required||y.required||z.required;

        [byAxis.X,byAxis.Y,byAxis.Z].forEach(v=>{
            v.input.required=false;
            v.label.classList.add('coordinate-source-hidden');
        });

        const label=document.createElement('label');
        label.className='field coordinate-combined-field';

        const title=document.createElement('span');
        title.textContent='Coordenadas (X,Y,Z)';

        const input=document.createElement('input');
        input.type='text';
        input.className='coordinate-combined-input';
        input.placeholder='46.63,-899.06,29.98';
        input.autocomplete='off';
        input.spellcheck=false;
        input.required=required;
        input.value=panelCoordinateText(x.value,y.value,z.value);

        label.append(title,input);
        grid.insertBefore(label,grid.firstElementChild);
        grid.dataset.coordCombined='1';

        bindCombinedCoordinateInput(input,x,y,z);
    });
}

function enhanceInlineCoordinateRows(scope=document){
    const configs=[
        {selector:'.spawnrow',x:'.sx',y:'.sy',z:'.sz',kind:'spawn'},
        {selector:'.shopcoordrow',x:'.px',y:'.py',z:'.pz',kind:'shop'},
        {selector:'.shopcoordrow',x:'.cx',y:'.cy',z:'.cz',kind:'craft'}
    ];

    configs.forEach(cfg=>{
        const rows=[
            ...(scope.matches?.(cfg.selector)?[scope]:[]),
            ...scope.querySelectorAll(cfg.selector)
        ];
        rows.forEach(row=>{
            if(row.dataset.coordCombined==='1')return;

            const x=row.querySelector(cfg.x);
            const y=row.querySelector(cfg.y);
            const z=row.querySelector(cfg.z);
            if(!x||!y||!z)return;

            [x,y,z].forEach(el=>{
                el.required=false;
                el.classList.add('coordinate-source-hidden');
            });

            const input=document.createElement('input');
            input.type='text';
            input.className='coordinate-combined-input coordinate-combined-row-input';
            input.placeholder='46.63,-899.06,29.98';
            input.autocomplete='off';
            input.spellcheck=false;
            input.value=panelCoordinateText(x.value,y.value,z.value);

            row.insertBefore(input,x);
            row.dataset.coordCombined='1';
            row.classList.add('coord-combined-row',`coord-combined-${cfg.kind}`);

            bindCombinedCoordinateInput(input,x,y,z);
        });
    });

    const coordHeads=[
        ...(scope.matches?.('.shopcoordhead')?[scope]:[]),
        ...scope.querySelectorAll('.shopcoordhead')
    ];
    coordHeads.forEach(head=>{
        if(head.dataset.coordCombined==='1')return;
        const spans=[...head.children];
        if(spans.length>=3 &&
           spans[0].textContent.trim().toUpperCase()==='X' &&
           spans[1].textContent.trim().toUpperCase()==='Y' &&
           spans[2].textContent.trim().toUpperCase()==='Z'){
            spans[0].textContent='Coordenadas (X,Y,Z)';
            spans[1].classList.add('coordinate-source-hidden');
            spans[2].classList.add('coordinate-source-hidden');
            head.classList.add('coord-combined-head');
            head.dataset.coordCombined='1';
        }
    });
}

function enhanceAllPanelCoordinates(scope=document){
    enhanceLabeledCoordinateGroups(scope);
    enhanceInlineCoordinateRows(scope);
}

function validateCombinedCoordinates(scope){
    const inputs=[...scope.querySelectorAll('.coordinate-combined-input')];
    for(const input of inputs){
        if(input.disabled)continue;
        const parsed=parsePanelCoordinate(input.value);
        if(!parsed){
            input.classList.add('coord-invalid');
            input.focus();
            warnInvalidPanelCoordinate(input);
            return false;
        }

        input.classList.remove('coord-invalid');
        const src=input._coordSources;
        if(src){
            src.x.value=parsed.x;
            src.y.value=parsed.y;
            src.z.value=parsed.z;
        }
    }
    return true;
}

document.addEventListener('submit',e=>{
    if(!e.target.closest('#drawer'))return;
    if(!validateCombinedCoordinates(e.target)){
        e.preventDefault();
        e.stopImmediatePropagation();
    }
},true);

const coordObserver=new MutationObserver(mutations=>{
    for(const mutation of mutations){
        mutation.addedNodes.forEach(node=>{
            if(node.nodeType===1)enhanceAllPanelCoordinates(node);
        });
    }
});

const coordDrawerBody=document.querySelector('#drawer-body');
if(coordDrawerBody){
    coordObserver.observe(coordDrawerBody,{childList:true,subtree:true});
    enhanceAllPanelCoordinates(coordDrawerBody);
}

/*
    Botões como "Usar minha posição" continuam escrevendo nos campos X/Y/Z
    internos. Este sincronizador mantém a caixa única visível atualizada sem
    alterar a lógica dos módulos existentes.
*/
setInterval(()=>{
    document.querySelectorAll('.coordinate-combined-input').forEach(input=>{
        if(document.activeElement===input)return;
        const src=input._coordSources;
        if(!src)return;
        const text=panelCoordinateText(src.x.value,src.y.value,src.z.value);
        if(text && input.value!==text){
            input.value=text;
            input.classList.remove('coord-invalid');
            input.dataset.coordValid='1';
        }
    });
},350);

function toast(msg,type='ok'){
    const n=document.createElement('div');
    n.className='toast'+(type==='error'?' error':'');
    n.innerHTML=`<b>${type==='error'?'Não foi possível concluir':'Tudo certo'}</b><span>${esc(msg||'Operação concluída.')}</span>`;
    $('#toasts').appendChild(n);
    setTimeout(()=>n.remove(),3200);
}
function stat(label,value,small){
    return `<article class="stat"><span>${label}</span><strong>${value}</strong><small>${small}</small></article>`;
}
function typeMap(){return Object.fromEntries(garageTypes.map(t=>[t.name,t.data]))}
const CFX_BLIP_CATALOG_URL='https://raw.githubusercontent.com/citizenfx/fivem-docs/refs/heads/master/content/docs/game-references/blips.md';
const CFX_BLIP_IMAGE_BASE='https://docs-backend.fivem.net/blips/';

let mapBlipCatalog={};
let mapBlipCatalogLoaded=false;
let mapBlipCatalogLoading=null;

/*
    Fallback mínimo para o caso de a documentação oficial estar
    temporariamente indisponível. O catálogo completo é carregado
    automaticamente do repositório oficial da Cfx.re.
*/
const MAP_BLIP_FALLBACK={
    56:'radar_cop_patrol.png',
    60:'radar_police_station.png',
    68:'radar_tow_truck.png',
    207:'radar_financier_strand_grey.png',
    310:'radar_deathmatch.png',
    318:'radar_garbage.png',
    326:'radar_getaway_car.png',
    351:'radar_gang_attack_package.png',
    378:'radar_team_deathmatch.png',
    446:'radar_bennys.png',
    477:'radar_truck.png',
    513:'radar_bus.png',
    617:'radar_bat_hack_jewel.png',
    618:'radar_bat_hack_gold.png',
    621:'radar_pickup_dtb_health.png'
};

function parseCfxBlipCatalog(markdown){
    const catalog={};

    /*
        A documentação oficial usa linhas como:
        <img src="/blips/radar_team_deathmatch.png" ...>
        ...
        <strong>378</strong>
        ...
        radar_team_deathmatch
    */
    const regex=/<div class="blip">[\s\S]*?<img\s+src="\/blips\/([^"]+)"[^>]*>[\s\S]*?<strong>(\d+)<\/strong>[\s\S]*?<\/div>/gi;
    let match;

    while((match=regex.exec(markdown))){
        const file=String(match[1]||'').trim();
        const id=Number(match[2]);

        if(Number.isFinite(id) && file){
            catalog[id]=file;
        }
    }

    return catalog;
}

async function loadMapBlipCatalog(force=false){
    if(mapBlipCatalogLoaded && !force)return mapBlipCatalog;
    if(mapBlipCatalogLoading && !force)return mapBlipCatalogLoading;

    mapBlipCatalogLoading=(async()=>{
        try{
            const response=await fetch(CFX_BLIP_CATALOG_URL,{
                method:'GET',
                cache:force?'no-store':'default'
            });

            if(!response.ok){
                throw new Error(`HTTP ${response.status}`);
            }

            const markdown=await response.text();
            const parsed=parseCfxBlipCatalog(markdown);

            if(Object.keys(parsed).length<100){
                throw new Error('Catálogo oficial retornou poucos blips.');
            }

            mapBlipCatalog=parsed;
            mapBlipCatalogLoaded=true;
        }catch(error){
            console.warn('[mg_config_panel] Não foi possível carregar o catálogo completo de blips da Cfx:',error);
            mapBlipCatalog={...MAP_BLIP_FALLBACK};
            mapBlipCatalogLoaded=false;
        }finally{
            mapBlipCatalogLoading=null;
        }

        return mapBlipCatalog;
    })();

    return mapBlipCatalogLoading;
}

function mapBlipFile(sprite){
    const id=Number(sprite);
    return mapBlipCatalog[id]||MAP_BLIP_FALLBACK[id]||'';
}

function mapBlipIconUrl(sprite){
    const file=mapBlipFile(sprite);
    return file?`${CFX_BLIP_IMAGE_BASE}${file}`:'';
}

function mapBlipFallback(sprite){
    return `<div class="mapblipfallback" title="Sprite ${esc(sprite)} sem imagem no catálogo">⌖</div>`;
}

function mapBlipIcon(sprite,cls='mapblipicon',lazy=false){
    const url=mapBlipIconUrl(sprite);

    if(!url){
        return mapBlipFallback(sprite);
    }

    const srcAttr=lazy?`data-src="${url}"`:`src="${url}"`;

    return `<div class="mapblipiconwrap" title="Sprite ${esc(sprite)}">
        <img
            class="${cls}${lazy?' lazy-blip':''}"
            ${srcAttr}
            alt="Blip ${esc(sprite)}"
            decoding="async"
            onerror="this.parentElement.innerHTML='<div class=&quot;mapblipfallback&quot; title=&quot;Imagem indisponível&quot;>⌖</div>'"
        >
    </div>`;
}

function refreshMapBlipIcons(){
    if(module!=='mapmarkings')return;

    /*
        render() reconstrói a listagem utilizando o catálogo recém
        carregado. Mantém também a prévia do drawer, se estiver aberta.
    */
    render();

    const preview=$('#mm-icon-preview');
    const spriteInput=$('#mm-sprite');

    if(preview && spriteInput){
        preview.innerHTML=mapBlipIcon(Number(spriteInput.value)||0,'mapblipicon large');
    }
}


const BLIP_COLOR_OPTIONS=[
    {id:0,name:'White',hex:'#ffffff'},
    {id:1,name:'Red',hex:'#e03232'},
    {id:2,name:'Green',hex:'#71cb71'},
    {id:3,name:'Blue',hex:'#5db6e5'},
    {id:4,name:'White',hex:'#f0f0f0'},
    {id:5,name:'Yellow',hex:'#f0cb58'},
    {id:6,name:'Light Red',hex:'#ed6a5a'},
    {id:7,name:'Violet',hex:'#b266ff'},
    {id:8,name:'Pink',hex:'#ff6ea8'},
    {id:9,name:'Light Orange',hex:'#f6a45b'},
    {id:10,name:'Light Brown',hex:'#c89b6d'},
    {id:11,name:'Light Green',hex:'#8ee68e'},
    {id:12,name:'Light Blue',hex:'#77c5ef'},
    {id:13,name:'Light Purple',hex:'#c69cff'},
    {id:14,name:'Dark Purple',hex:'#6d3aa6'},
    {id:15,name:'Cyan',hex:'#00d7d7'},
    {id:16,name:'Light Yellow',hex:'#fff08a'},
    {id:17,name:'Orange',hex:'#f7931e'},
    {id:18,name:'Light Blue',hex:'#8fd3ff'},
    {id:19,name:'Dark Pink',hex:'#c94d84'},
    {id:20,name:'Dark Yellow',hex:'#b7952b'},
    {id:21,name:'Dark Orange',hex:'#b76519'},
    {id:22,name:'Light Gray',hex:'#c7c7c7'},
    {id:23,name:'Light Pink',hex:'#ff9fc5'},
    {id:24,name:'Lemon Green',hex:'#b7e33c'},
    {id:25,name:'Forest Green',hex:'#2d7d46'},
    {id:26,name:'Electric Blue',hex:'#3f7cff'},
    {id:27,name:'Bright Purple',hex:'#b341ff'},
    {id:28,name:'Dark Yellow',hex:'#b08a1d'},
    {id:29,name:'Dark Blue',hex:'#284a8a'},
    {id:30,name:'Dark Cyan',hex:'#227c86'},
    {id:31,name:'Light Brown',hex:'#c49a72'},
    {id:32,name:'Light Blue',hex:'#8dc8f0'},
    {id:33,name:'Light Yellow',hex:'#ffe68a'},
    {id:34,name:'Light Pink',hex:'#ffabd0'},
    {id:35,name:'Light Red',hex:'#ff8585'},
    {id:36,name:'Beige',hex:'#d8c4a8'},
    {id:37,name:'White',hex:'#ffffff'},
    {id:38,name:'Blue',hex:'#4b8ee8'},
    {id:39,name:'Light Gray',hex:'#bfc6cf'},
    {id:40,name:'Dark Gray',hex:'#6a6f78'},
    {id:41,name:'Pink Red',hex:'#d84c79'},
    {id:42,name:'Blue',hex:'#3475d4'},
    {id:43,name:'Light Green',hex:'#89d68e'},
    {id:44,name:'Light Orange',hex:'#f2a65a'},
    {id:45,name:'White',hex:'#f5f5f5'},
    {id:46,name:'Gold',hex:'#d9b24c'},
    {id:47,name:'Orange',hex:'#f47a23'},
    {id:48,name:'Brilliant Rose',hex:'#e84a9b'},
    {id:49,name:'Red',hex:'#d83b3b'},
    {id:50,name:'Medium Purple',hex:'#9365c7'},
    {id:51,name:'Salmon',hex:'#ef8172'},
    {id:52,name:'Dark Green',hex:'#285c3b'},
    {id:53,name:'Blizzard Blue',hex:'#9ed7df'},
    {id:54,name:'Oracle Blue',hex:'#4e8aa6'},
    {id:55,name:'Silver',hex:'#b9bec5'},
    {id:56,name:'Brown',hex:'#876241'},
    {id:57,name:'Blue',hex:'#4276bd'},
    {id:58,name:'East Bay',hex:'#4b527d'},
    {id:59,name:'Red',hex:'#c93636'},
    {id:60,name:'Yellow Orange',hex:'#f4a52c'},
    {id:61,name:'Mulberry Pink',hex:'#b94a86'},
    {id:62,name:'Alto Gray',hex:'#d0d0d0'},
    {id:63,name:'Jelly Bean Blue',hex:'#438ca6'},
    {id:64,name:'Dark Orange',hex:'#a8521d'},
    {id:65,name:'Mamba',hex:'#8b7d91'},
    {id:66,name:'Yellow Orange',hex:'#f0a128'},
    {id:67,name:'Blue',hex:'#3e75c7'},
    {id:68,name:'Blue',hex:'#3870ba'},
    {id:69,name:'Green',hex:'#4ea75a'},
    {id:70,name:'Yellow Orange',hex:'#e99b25'},
    {id:71,name:'Yellow Orange',hex:'#f1a333'},
    {id:72,name:'Transparent Black',hex:'#333333'},
    {id:73,name:'Yellow Orange',hex:'#f1a333'},
    {id:74,name:'Blue',hex:'#3c73ba'},
    {id:75,name:'Red',hex:'#d93b3b'},
    {id:76,name:'Deep Red',hex:'#8b1d24'},
    {id:77,name:'Blue',hex:'#326cb2'},
    {id:78,name:'Oracle Blue',hex:'#4e8aa6'},
    {id:79,name:'Transparent Red',hex:'#b94a4a'},
    {id:80,name:'Transparent Blue',hex:'#4c7fa8'}
];

let mapPickerMode=null;
let mapPickerVisibleCount=60;
let mapPickerObserver=null;
let mapPickerSearchTimer=null;
const MAP_PICKER_BATCH=60;


function cleanupMapPickerObserver(){
    if(mapPickerObserver){
        mapPickerObserver.disconnect();
        mapPickerObserver=null;
    }
}

function activateLazyBlipImages(){
    cleanupMapPickerObserver();

    const images=[...document.querySelectorAll('#map-picker-grid img.lazy-blip[data-src]')];
    if(!images.length)return;

    mapPickerObserver=new IntersectionObserver(entries=>{
        entries.forEach(entry=>{
            if(!entry.isIntersecting)return;

            const img=entry.target;
            const src=img.dataset.src;
            if(src){
                img.src=src;
                img.removeAttribute('data-src');
            }
            mapPickerObserver.unobserve(img);
        });
    },{
        root:$('#map-picker-grid'),
        rootMargin:'180px 0px'
    });

    images.forEach(img=>mapPickerObserver.observe(img));
}

function resetMapPickerBatch(){
    mapPickerVisibleCount=MAP_PICKER_BATCH;
}

function ensureMapPickerModal(){
    if($('#map-picker-modal'))return;

    document.body.insertAdjacentHTML('beforeend',`
        <div id="map-picker-modal" class="map-picker-modal hidden">
            <div class="map-picker-card">
                <div class="map-picker-head">
                    <div>
                        <small id="map-picker-kicker">SELECIONAR</small>
                        <h3 id="map-picker-title">Escolher</h3>
                    </div>
                    <button type="button" id="map-picker-close" class="rowbtn">×</button>
                </div>

                <div id="map-picker-search-wrap" class="map-picker-search-wrap">
                    <input id="map-picker-search" placeholder="Buscar por ID ou nome...">
                </div>

                <div id="map-picker-grid" class="map-picker-grid"></div>
            </div>
        </div>
    `);

    $('#map-picker-close').onclick=closeMapPicker;
    $('#map-picker-modal').onclick=e=>{
        if(e.target===$('#map-picker-modal'))closeMapPicker();
    };
    $('#map-picker-search').oninput=()=>{
        clearTimeout(mapPickerSearchTimer);
        mapPickerSearchTimer=setTimeout(()=>{
            resetMapPickerBatch();
            renderMapPicker();
        },120);
    };
    $('#map-picker-grid').addEventListener('scroll',()=>{
        if(mapPickerMode!=='sprite')return;

        const grid=$('#map-picker-grid');
        if(grid.scrollTop+grid.clientHeight < grid.scrollHeight-220)return;

        const total=Number(grid.dataset.total||0);
        if(mapPickerVisibleCount>=total)return;

        mapPickerVisibleCount=Math.min(mapPickerVisibleCount+MAP_PICKER_BATCH,total);
        renderMapPicker(true);
    });

}

function closeMapPicker(){
    $('#map-picker-modal')?.classList.add('hidden');
    cleanupMapPickerObserver();
    clearTimeout(mapPickerSearchTimer);
    mapPickerMode=null;
}


document.addEventListener('keydown',function(e){
    if(e.key!=='Escape')return;

    const picker=$('#map-picker-modal');
    if(!picker || picker.classList.contains('hidden'))return;

    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    closeMapPicker();
},true);

function spriteDisplayName(file){
    return String(file||'')
        .replace(/\.(png|gif|webp)$/i,'')
        .replace(/^radar_/i,'')
        .replace(/_/g,' ');
}

async function openSpritePicker(){
    ensureMapPickerModal();
    await loadMapBlipCatalog();

    mapPickerMode='sprite';
    resetMapPickerBatch();
    $('#map-picker-kicker').textContent='BLIPS DISPONÍVEIS';
    $('#map-picker-title').textContent='Escolher sprite';
    $('#map-picker-search-wrap').classList.remove('hidden');
    $('#map-picker-search').value='';
    $('#map-picker-modal').classList.remove('hidden');

    renderMapPicker();
    setTimeout(()=>$('#map-picker-search').focus(),20);
}

function openColorPicker(){
    ensureMapPickerModal();

    mapPickerMode='color';
    resetMapPickerBatch();
    $('#map-picker-kicker').textContent='CORES DE BLIP';
    $('#map-picker-title').textContent='Escolher cor';
    $('#map-picker-search-wrap').classList.remove('hidden');
    $('#map-picker-search').value='';
    $('#map-picker-modal').classList.remove('hidden');

    renderMapPicker();
    setTimeout(()=>$('#map-picker-search').focus(),20);
}

function renderMapPicker(){
    const grid=$('#map-picker-grid');
    if(!grid)return;

    const q=($('#map-picker-search')?.value||'').trim().toLowerCase();

    if(mapPickerMode==='sprite'){
        const entries=Object.entries(mapBlipCatalog)
            .map(([id,file])=>({id:Number(id),file}))
            .filter(x=>
                !q ||
                String(x.id).includes(q) ||
                String(x.file).toLowerCase().includes(q) ||
                spriteDisplayName(x.file).toLowerCase().includes(q)
            )
            .sort((a,b)=>a.id-b.id);

        const visible=entries.slice(0,mapPickerVisibleCount);

        grid.className='map-picker-grid sprite-grid';
        grid.dataset.total=String(entries.length);
        grid.innerHTML=visible.map(x=>`
            <button type="button" class="sprite-choice" data-id="${x.id}">
                ${mapBlipIcon(x.id,'mapblipicon picker',true)}
                <div>
                    <b>${x.id}</b>
                    <span>${esc(spriteDisplayName(x.file))}</span>
                    <small>${esc(String(x.file).replace(/\.(png|gif|webp)$/i,''))}</small>
                </div>
            </button>
        `).join('') + (visible.length<entries.length?`
            <div class="sprite-load-status">
                Mostrando ${visible.length} de ${entries.length} sprites • role para carregar mais
            </div>
        `:'');

        $$('.sprite-choice').forEach(btn=>btn.onclick=()=>{
            const id=Number(btn.dataset.id);
            $('#mm-sprite').value=id;
            $('#mm-sprite').dispatchEvent(new Event('input',{bubbles:true}));
            closeMapPicker();
        });

        activateLazyBlipImages();
        return;
    }

    if(mapPickerMode==='color'){
        const colors=BLIP_COLOR_OPTIONS.filter(x=>
            !q ||
            String(x.id).includes(q) ||
            x.name.toLowerCase().includes(q)
        );

        grid.className='map-picker-grid color-grid';
        grid.innerHTML=colors.map(x=>`
            <button type="button" class="color-choice" data-id="${x.id}">
                <span class="color-swatch" style="background:${x.hex}"></span>
                <div>
                    <b>ID ${x.id}</b>
                    <span>${esc(x.name)}</span>
                </div>
            </button>
        `).join('');

        $$('.color-choice').forEach(btn=>btn.onclick=()=>{
            const id=Number(btn.dataset.id);
            $('#mm-color').value=id;
            updateMapColorPreview();
            closeMapPicker();
        });
    }
}

function getBlipColorOption(id){
    return BLIP_COLOR_OPTIONS.find(x=>x.id===Number(id));
}

function updateMapColorPreview(){
    const input=$('#mm-color');
    const preview=$('#mm-color-preview');
    const label=$('#mm-color-label');
    if(!input||!preview||!label)return;

    const option=getBlipColorOption(input.value);
    preview.style.background=option?.hex||'#777';
    label.textContent=option?`ID ${option.id} • ${option.name}`:`ID ${input.value}`;
}


async function loadAll(silent=false){
    loadMapBlipCatalog().then(()=>refreshMapBlipIcons());
    const [a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v]=await Promise.all([
        nui('getChests'),
        nui('getGarages'),
        nui('getGarageTypes'),
        nui('getShops'),
        nui('getCraftSetups'),
        nui('getClothingShops'),
        nui('getBarbershops'),
        nui('getTattooShops'),
        nui('getCloakrooms'),
        nui('getMapMarkings'),
        nui('getManagedGroups'),
        nui('getDesmanches'),
        nui('getSafeZones'),
        nui('getJobs'),
        nui('getRoubos'),
        nui('getBancoCentral'),
        nui('getJoalheria'),
        nui('getRoubocofre'),
        nui('getResidences'),
        nui('getDealership'),
        nui('getServerVehicleCatalog'),
        nui('getMansions')
    ]);

    if(a.ok) chests=a.data||[];
    if(b.ok) garages=b.data||[];
    if(c.ok) garageTypes=c.data||[];
    if(d.ok) shops=d.data||[];
    if(e.ok) craftSetups=e.data||{benches:[],farm:{}};
    if(f.ok) clothingShops=f.data||[];
    if(g.ok) barbershops=g.data||[];
    if(h.ok) tattooShops=h.data||[];
    if(i.ok) cloakrooms=i.data||[];
    if(j.ok) mapMarkings=j.data||[];
    if(k.ok) managedGroups=k.data||[];
    if(l.ok){
        desmanches=l.data?.desmanches||[];
        desmancheSettings=l.data?.settings||{};
    }
    if(m.ok){
        safeZones=m.data?.safezones||[];
        safeZoneSettings=m.data?.settings||{};
        safeZoneWhitelist=m.data?.whitelist||[];
    }
    if(n.ok){
        jobsData=n.data||{jobs:{},extras:{},central:[],npc:[]};
    }
    if(o.ok){
        robberiesData=o.data||{locations:[],setups:{},webhooks:{},settings:{}};
    }
    if(p.ok){
        bancoCentralData=p.data||{name:'Banco Central',settings:{},banks:[]};
    }
    if(q.ok){
        joalheriaData=q.data||{name:'Joalheria',settings:{},rewards:[],displays:[]};
    }
    if(r.ok){
        roubocofreData=r.data||{name:'Roubo a Cofres',settings:{},banks:{}};
    }
    if(s.ok){
        residencesData=s.data||{settings:{},interiors:{},residences:[]};
    }
    if(t.ok){
        dealershipData=t.data||{settings:{},testDrive:{},categories:[],vips:[],vehicles:{},runtimeVehicles:{}};
    }
    if(u.ok){
        serverVehicleCatalog=u.data||{};
    }
    if(v.ok){
        mansionsData=v.data||{mansions:[]};
    }










    updateModuleFilters(false);
    render();

    const failed=[a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v].find(x=>!x.ok);
    if(failed) toast(failed.message||'Algum módulo não pôde ser carregado.','error');
    else if(!silent) toast('Configurações atualizadas.');
}


function setSelectOptions(el,options,value=null){
    if(!el)return;
    const current=value??el.value;
    el.innerHTML=options.map(o=>`<option value="${esc(o[0])}">${esc(o[1])}</option>`).join('');
    if(options.some(o=>String(o[0])===String(current)))el.value=current;
    else if(options.length)el.value=options[0][0];
}

function updateModuleFilters(reset=false){
    const sortEl=$('#sort');
    const filterEl=$('#group-filter');
    if(!sortEl||!filterEl)return;

    let sortOptions=[['name','Ordenar por nome']];
    let filterOptions=[['all','Todos']];
    let showFilter=true;

    if(module==='groups'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['type','Ordenar por tipo'],
            ['org','Ordenar por organização'],
            ['salary','Ordenar por salário'],
            ['permissions','Ordenar por permissões']
        ];
        filterOptions=[
            ['all','Todos os cargos'],
            ['staff','Somente Staff'],
            ['org','Somente Organizações'],
            ['emp','Somente Empregos'],
            ['dm','Somente Dominas / DM'],
            ['other','Outros tipos']
        ];
    }else if(module==='chests'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['weight','Ordenar por peso'],
            ['permission','Ordenar por permissão']
        ];
        filterOptions=[
            ['all','Todos os baús'],
            ['free','Acesso livre'],
            ['restricted','Com permissão']
        ];
    }else if(module==='garages' && garageTab==='points'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['type','Ordenar por tipo'],
            ['permission','Ordenar por permissão'],
            ['spawns','Ordenar por vagas']
        ];
        filterOptions=[
            ['all','Todas as garagens'],
            ['free','Garagens públicas'],
            ['restricted','Com permissão'],
            ...garageTypes.map(t=>[`type:${t.name}`,`Tipo: ${t.name}`])
        ];
    }else if(module==='garages'){
        sortOptions=[['name','Ordenar por nome']];
        filterOptions=[['all','Todos os tipos']];
        showFilter=false;
    }else if(module==='shops'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['mode','Ordenar por modo'],
            ['items','Ordenar por itens'],
            ['points','Ordenar por pontos']
        ];
        filterOptions=[
            ['all','Todas as lojas'],
            ['buy','Somente compra'],
            ['sell','Somente venda'],
            ['free','Acesso livre'],
            ['restricted','Com permissão']
        ];
    }else if(module==='craft'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['recipes','Ordenar por receitas'],
            ['points','Ordenar por pontos'],
            ['farm','Ordenar por farm']
        ];
        filterOptions=[
            ['all','Todas as bancadas'],
            ['withfarm','Com Farm'],
            ['nofarm','Sem Farm'],
            ['restricted','Com permissão']
        ];
    }else if(module==='cloakroom'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['permission','Ordenar por permissão'],
            ['uniforms','Ordenar por fardamentos']
        ];
        filterOptions=[
            ['all','Todos os fardamentos'],
            ['free','Acesso livre'],
            ['restricted','Com permissão'],
            ['withuniform','Com uniformes cadastrados']
        ];
    }else if(module==='mapmarkings'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['sprite','Ordenar por sprite'],
            ['color','Ordenar por cor'],
            ['scale','Ordenar por escala']
        ];
        const colors=[...new Set(mapMarkings.map(x=>String(x.color??'')))].filter(Boolean).sort((a,b)=>Number(a)-Number(b));
        filterOptions=[
            ['all','Todas as marcações'],
            ...colors.map(c=>[`color:${c}`,`Cor ${c}`])
        ];
    }else if(module==='dealership'){
        if(dealershipView==='server'){
            sortOptions=[
                ['name','Ordenar por nome'],
                ['spawn','Ordenar por spawn'],
                ['type','Ordenar por tipo'],
                ['price','Ordenar por valor'],
                ['trunk','Ordenar por porta-malas']
            ];
            const serverTypes=[...new Set(Object.values(serverVehicleCatalog||{}).map(v=>String(v.type||'outros')))].sort();
            filterOptions=[
                ['all','Todos os veículos'],
                ['banned','Somente bloqueados'],
                ['available','Somente liberados'],
                ...serverTypes.map(t=>[`type:${t}`,`Tipo: ${t}`])
            ];
        }else{
            sortOptions=[
                ['name','Ordenar por nome'],
                ['spawn','Ordenar por spawn'],
                ['category','Ordenar por categoria'],
                ['price','Ordenar por valor'],
                ['stock','Ordenar por estoque'],
                ['trunk','Ordenar por porta-malas']
            ];
            const cats=(dealershipData.categories||[]).map(c=>[c.id,c.label||c.id]);
            filterOptions=[
                ['all','Todos os veículos'],
                ['stock','Somente com estoque'],
                ['nostock','Sem estoque'],
                ...cats.map(c=>[`category:${c[0]}`,`Categoria: ${c[1]}`])
            ];
        }
    }else if(module==='houses'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['type','Ordenar por tipo'],
            ['interior','Ordenar por interior'],
            ['price','Ordenar por valor']
        ];
        const interiors=[...new Set((residencesData.residences||[]).map(x=>x.interior).filter(Boolean))].sort();
        filterOptions=[
            ['all','Todas as residências'],
            ['house','Somente Casas'],
            ['apartment','Somente Apartamentos'],
            ...interiors.map(i=>[`interior:${i}`,`Interior: ${i}`])
        ];
    }else if(module==='robberies'){
        sortOptions=[
            ['name','Ordenar por sistema'],
            ['resource','Ordenar por resource']
        ];
        filterOptions=[
            ['all','Todos os roubos'],
            ['commerce','Roubos de Comércio'],
            ['central','Banco Central'],
            ['jewelry','Joalheria'],
            ['vault','Roubo a Cofres']
        ];
    }else if(module==='jobs'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['levels','Ordenar por níveis'],
            ['payment','Ordenar por pagamentos'],
            ['uniform','Ordenar por uniforme']
        ];
        filterOptions=[
            ['all','Todos os empregos'],
            ['uniform','Com uniforme'],
            ['nouniform','Sem uniforme'],
            ['multilevel','Mais de 1 nível']
        ];
    }else if(module==='safezone'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['polygons','Ordenar por polígonos'],
            ['points','Ordenar por pontos'],
            ['height','Ordenar por altura']
        ];
        filterOptions=[
            ['all','Todas as SafeZones'],
            ['debug','Debug ativo'],
            ['nodebug','Debug desativado'],
            ['multi','Com múltiplos polígonos']
        ];
    }else if(module==='mansions'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['price','Ordenar por valor'],
            ['residents','Ordenar por moradores']
        ];
        filterOptions=[
            ['all','Todas as mansões'],
            ['free','Disponíveis'],
            ['occupied','Com proprietário']
        ];
    }else if(module==='desmanche'){
        sortOptions=[
            ['name','Ordenar por nome'],
            ['permission','Ordenar por permissão'],
            ['item','Ordenar por exigência de item']
        ];
        filterOptions=[
            ['all','Todos os desmanches'],
            ['item','Exigem item'],
            ['noitem','Não exigem item']
        ];
    }else if(['clothing','barbershop','tattoo'].includes(module)){
        sortOptions=[
            ['id','Ordenar por ID'],
            ['x','Ordenar por coordenada X']
        ];
        showFilter=false;
    }else{
        sortOptions=[['name','Ordenar por nome']];
        showFilter=false;
    }

    setSelectOptions(sortEl,sortOptions,reset?sortOptions[0][0]:sortEl.value);
    setSelectOptions(filterEl,filterOptions,reset?'all':filterEl.value);
    filterEl.classList.toggle('hidden',!showFilter);
}

function setModule(m){
    module=m;
    editing=null;

    if(m==='mapmarkings'){
        loadMapBlipCatalog().then(()=>refreshMapBlipIcons());
    }
    $$('.nav[data-module]').forEach(x=>x.classList.toggle('active',x.dataset.module===m));
    $('#garage-tabs').classList.toggle('hidden',m!=='garages');
    garageTab='points';
    $$('.tab').forEach(x=>x.classList.toggle('active',x.dataset.tab==='points'));
    updateModuleFilters(true);
    render();
}

function currentKind(){
    if(module==='chests') return 'chest';
    if(module==='shops') return 'shop';
    if(module==='craft') return 'craft';
    if(module==='clothing') return 'clothing';
    if(module==='barbershop') return 'barbershop';
    if(module==='tattoo') return 'tattoo';
    if(module==='cloakroom') return 'cloakroom';
    if(module==='mapmarkings') return 'mapmarking';
    if(module==='groups') return 'group';
    if(module==='desmanche') return 'desmanche';
    if(module==='safezone') return 'safezone';
    if(module==='jobs') return 'job';
    if(module==='robberies') return 'robberyhub';
    if(module==='houses') return 'residence';
    if(module==='mansions') return 'mansion';
    if(module==='dealership') return 'dealershipvehicle';
    return garageTab==='points'?'garage':'type';
}

function actions(kind,id,canTp=true){
    return `<div class="rowactions">
        ${canTp?`<button class="rowbtn" data-a="tp" data-k="${kind}" data-id="${enc(id)}" title="Teleportar">⌖</button>`:''}
        <button class="rowbtn" data-a="edit" data-k="${kind}" data-id="${enc(id)}" title="Editar">✎</button>
        <button class="rowbtn del" data-a="del" data-k="${kind}" data-id="${enc(id)}" title="Excluir">×</button>
    </div>`;
}


function groupTypeLabel(type){
    return {
        staff:'Staff',
        org:'Organização',
        emp:'Emprego',
        dm:'Dominas / DM'
    }[type]||type||'Sem tipo';
}

function groupPermissionSlug(name){
    return String(name||'')
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g,'')
        .toLowerCase()
        .replace(/[^a-z0-9]/g,'');
}

function groupDefaultPermission(name){
    const slug=groupPermissionSlug(name);
    return slug?`perm.${slug}`:'';
}

function groupOrgSortKey(group){
    const orgName=String(group?.config?.orgName||'').trim();
    if(orgName)return orgName;

    /*
        Fallback para cargos antigos sem orgName.
        Remove prefixos hierárquicos comuns e usa o restante como
        identificador da organização. Ex:
        RecrutadorColombia -> Colombia
        NovatoColombia -> Colombia
        GerenteColombia -> Colombia
        SoldadoPM -> PM
    */
    let name=String(group?.name||'').trim();

    const prefixes=[
        'recrutador','novato','gerente','lider','líder','sub-lider','sublider',
        'subchefe','chefe','membro','soldado','cabo','sargento','tenente',
        'capitao','capitão','major','coronel','comandante','diretor',
        'vice','administrador','admin','coordenador','supervisor'
    ];

    const normalized=name
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g,'');

    const lower=normalized.toLowerCase();

    for(const prefix of prefixes){
        const p=prefix
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g,'')
            .toLowerCase();

        if(lower.startsWith(p) && normalized.length>p.length){
            name=normalized.slice(p.length).replace(/^[-_\s]+/,'');
            break;
        }
    }

    return name||String(group?.name||'');
}



function syncGroupTopActions(){
    const newBtn=$('#new');
    if(!newBtn)return;

    let facBtn=$('#new-fac');
    let deleteFacBtn=$('#delete-fac');
    let desSettingsBtn=$('#des-settings');
    let safeSettingsBtn=$('#safe-settings');
    let jobsSettingsBtn=$('#jobs-settings');
    let housesInteriorsBtn=$('#houses-interiors');
    let housesSettingsBtn=$('#houses-settings');
    let dealershipSettingsBtn=$('#dealership-settings');
    let serverVehicleBtn=$('#server-vehicle-new');
    let serverVehicleListBtn=$('#server-vehicle-list');
    let serverVehicleBulkBtn=$('#server-vehicle-bulk');
    let serverVehicleBulkDeleteBtn=$('#server-vehicle-bulk-delete');

    if(module==='groups'){
        if(!facBtn){
            newBtn.insertAdjacentHTML(
                'afterend',
                '<button id="new-fac" class="btn ghost">＋ Cadastrar FAC</button>'
            );
            facBtn=$('#new-fac');
            facBtn.onclick=()=>openDrawer('fac');
        }

        if(!deleteFacBtn){
            facBtn.insertAdjacentHTML(
                'afterend',
                '<button id="delete-fac" class="btn ghost danger-outline">− Excluir FAC</button>'
            );
            deleteFacBtn=$('#delete-fac');
            deleteFacBtn.onclick=()=>deleteFacForm();
        }

        facBtn.classList.remove('hidden');
        deleteFacBtn.classList.remove('hidden');
    }else{
        if(facBtn)facBtn.classList.add('hidden');
        if(deleteFacBtn)deleteFacBtn.classList.add('hidden');
    }

    if(module==='desmanche'){
        if(!desSettingsBtn){
            newBtn.insertAdjacentHTML(
                'afterend',
                '<button id="des-settings" class="btn ghost">⚙ Configurações</button>'
            );
            desSettingsBtn=$('#des-settings');
            desSettingsBtn.onclick=()=>desmancheSettingsForm();
        }
        desSettingsBtn.classList.remove('hidden');
    }else if(desSettingsBtn){
        desSettingsBtn.classList.add('hidden');
    }

    if(module==='safezone'){
        if(!safeSettingsBtn){
            newBtn.insertAdjacentHTML(
                'afterend',
                '<button id="safe-settings" class="btn ghost">⚙ Configurações</button>'
            );
            safeSettingsBtn=$('#safe-settings');
            safeSettingsBtn.onclick=()=>safeZoneSettingsForm();
        }
        safeSettingsBtn.classList.remove('hidden');
    }else if(safeSettingsBtn){
        safeSettingsBtn.classList.add('hidden');
    }

    if(module==='jobs'){
        if(!jobsSettingsBtn){
            newBtn.insertAdjacentHTML('afterend','<button id="jobs-settings" class="btn ghost">⚙ Central / NPC</button>');
            jobsSettingsBtn=$('#jobs-settings');
            jobsSettingsBtn.onclick=()=>jobsGlobalForm();
        }
        jobsSettingsBtn.classList.remove('hidden');
        newBtn.classList.add('hidden');
    }else{
        if(jobsSettingsBtn)jobsSettingsBtn.classList.add('hidden');
        newBtn.classList.remove('hidden');
    }

    if(module==='houses'){
        if(!housesInteriorsBtn){
            newBtn.insertAdjacentHTML('afterend','<button id="houses-interiors" class="btn ghost">⌂ Interiores</button>');
            housesInteriorsBtn=$('#houses-interiors');
            housesInteriorsBtn.onclick=()=>residenceInteriorsList();
        }
        if(!housesSettingsBtn){
            housesInteriorsBtn.insertAdjacentHTML('afterend','<button id="houses-settings" class="btn ghost">⚙ Configurações</button>');
            housesSettingsBtn=$('#houses-settings');
            housesSettingsBtn.onclick=()=>residencesSettingsForm();
        }
        housesInteriorsBtn.classList.remove('hidden');
        housesSettingsBtn.classList.remove('hidden');
    }else{
        if(housesInteriorsBtn)housesInteriorsBtn.classList.add('hidden');
        if(housesSettingsBtn)housesSettingsBtn.classList.add('hidden');
    }

    if(module==='dealership'){
        if(!serverVehicleListBtn){
            newBtn.insertAdjacentHTML('afterend','<button id="server-vehicle-list" class="btn ghost">▦ Veículos cadastrados servidor</button>');
            serverVehicleListBtn=$('#server-vehicle-list');
            serverVehicleListBtn.onclick=()=>{
                dealershipView=dealershipView==='server'?'dealership':'server';
                serverVehicleBulkMode=false;
                serverVehicleBulkSelection.clear();
                updateModuleFilters(true);
                render();
                syncGroupTopActions();
            };
        }
        if(!serverVehicleBtn){
            serverVehicleListBtn.insertAdjacentHTML('afterend','<button id="server-vehicle-new" class="btn ghost">＋ Cadastrar veículo servidor</button>');
            serverVehicleBtn=$('#server-vehicle-new');
            serverVehicleBtn.onclick=()=>serverVehicleForm(null);
        }
        if(!serverVehicleBulkBtn){
            serverVehicleBtn.insertAdjacentHTML('afterend','<button id="server-vehicle-bulk" class="btn ghost danger-outline">− Remover vários</button>');
            serverVehicleBulkBtn=$('#server-vehicle-bulk');
            serverVehicleBulkBtn.onclick=()=>{
                serverVehicleBulkMode=!serverVehicleBulkMode;
                serverVehicleBulkSelection.clear();
                render();
                syncGroupTopActions();
            };
        }
        if(!serverVehicleBulkDeleteBtn){
            serverVehicleBulkBtn.insertAdjacentHTML('afterend','<button id="server-vehicle-bulk-delete" class="btn dangerbtn hidden">Apagar selecionados (0)</button>');
            serverVehicleBulkDeleteBtn=$('#server-vehicle-bulk-delete');
            serverVehicleBulkDeleteBtn.onclick=()=>openServerVehicleBulkConfirm();
        }
        if(!dealershipSettingsBtn){
            serverVehicleBtn.insertAdjacentHTML('afterend','<button id="dealership-settings" class="btn ghost">⚙ Configurações / VIPs</button>');
            dealershipSettingsBtn=$('#dealership-settings');
            dealershipSettingsBtn.onclick=()=>dealershipSettingsForm();
        }

        serverVehicleListBtn.textContent=dealershipView==='server'?'▰ Voltar para concessionária':'▦ Veículos cadastrados servidor';
        serverVehicleListBtn.classList.remove('hidden');
        serverVehicleBtn.classList.remove('hidden');
        dealershipSettingsBtn.classList.remove('hidden');

        const bulkVisible=dealershipView==='server';
        serverVehicleBulkBtn.classList.toggle('hidden',!bulkVisible);
        serverVehicleBulkBtn.textContent=serverVehicleBulkMode?'× Cancelar seleção':'− Remover vários';
        serverVehicleBulkDeleteBtn.classList.toggle('hidden',!bulkVisible||!serverVehicleBulkMode);
        serverVehicleBulkDeleteBtn.textContent=`Apagar selecionados (${serverVehicleBulkSelection.size})`;
        serverVehicleBulkDeleteBtn.disabled=serverVehicleBulkSelection.size===0;

        newBtn.textContent='＋ Cadastrar veículo concessionária';
        newBtn.onclick=()=>openDrawer('dealershipvehicle',null);
    }else{
        dealershipView='dealership';
        serverVehicleBulkMode=false;
        serverVehicleBulkSelection.clear();
        if(serverVehicleListBtn)serverVehicleListBtn.classList.add('hidden');
        if(serverVehicleBtn)serverVehicleBtn.classList.add('hidden');
        if(serverVehicleBulkBtn)serverVehicleBulkBtn.classList.add('hidden');
        if(serverVehicleBulkDeleteBtn)serverVehicleBulkDeleteBtn.classList.add('hidden');
        if(dealershipSettingsBtn)dealershipSettingsBtn.classList.add('hidden');
    }
}

function render(){
    syncGroupTopActions();
    const q=$('#search').value.trim().toLowerCase();
    const sort=$('#sort').value;
    let html='', head='';

    if(module==='chests'){
        $('#page-title').textContent='Gerenciar Baús';
        $('#page-sub').textContent='Crie, edite e organize pontos de armazenamento sem alterar o código.';
        $('#new').textContent='＋ Novo baú';
        $('#stats').innerHTML=
            stat('Total de baús',chests.length,'cadastrados no JSON')+
            stat('Peso total',chests.reduce((a,c)=>a+(+c.weight||0),0).toLocaleString('pt-BR'),'capacidade configurada')+
            stat('Com permissão',chests.filter(c=>c.permission).length,'acesso restrito');

        head='<tr><th>Baú</th><th>Permissão</th><th>Peso</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=chests.filter(c=>{
            const search=!q||c.name.toLowerCase().includes(q)||String(c.permission).toLowerCase().includes(q);
            const contextual=filter==='all'||(filter==='free'&&!c.permission)||(filter==='restricted'&&!!c.permission);
            return search&&contextual;
        });
        arr.sort((a,b)=>{
            if(sort==='weight')return (Number(b.weight)||0)-(Number(a.weight)||0);
            if(sort==='permission')return String(a.permission||'').localeCompare(String(b.permission||''))||a.name.localeCompare(b.name);
            return a.name.localeCompare(b.name);
        });

        html=arr.map(c=>`<tr>
            <td>${esc(c.name)}</td>
            <td>${c.permission?`<span class="pill">${esc(c.permission)}</span>`:'<span class="muted">Sem permissão</span>'}</td>
            <td>${(+c.weight||0).toLocaleString('pt-BR')} kg</td>
            <td class="mono">${f(c.coords.x)}, ${f(c.coords.y)}, ${f(c.coords.z)}</td>
            <td class="actions">${actions('chest',c.name,true)}</td>
        </tr>`).join('');
    }else if(module==='garages' && garageTab==='points'){
        $('#page-title').textContent='Gerenciar Garagens';
        $('#page-sub').textContent='Cadastre pontos, permissões e múltiplas vagas de spawn em tempo real.';
        $('#new').textContent='＋ Nova garagem';
        $('#stats').innerHTML=
            stat('Pontos de garagem',garages.length,'cadastrados no JSON')+
            stat('Tipos em uso',new Set(garages.map(g=>g.type)).size,'categorias utilizadas')+
            stat('Vagas de spawn',garages.reduce((a,g)=>a+(g.spawnCoords?.length||0),0),'pontos configurados');

        head='<tr><th>Identificador</th><th>Tipo</th><th>Permissão</th><th>Vagas</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=garages.filter(g=>{
            const search=!q||String(g.id).toLowerCase().includes(q)||String(g.type).toLowerCase().includes(q)||String(g.permiss||'').toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='free'&&!g.permiss)||
                (filter==='restricted'&&!!g.permiss)||
                (filter.startsWith('type:')&&String(g.type)===filter.slice(5));
            return search&&contextual;
        });
        arr.sort((a,b)=>{
            if(sort==='type') return String(a.type).localeCompare(String(b.type));
            if(sort==='permission') return String(a.permiss||'').localeCompare(String(b.permiss||''))||String(a.id).localeCompare(String(b.id));
            if(sort==='spawns') return (b.spawnCoords?.length||0)-(a.spawnCoords?.length||0);

            const aId=String(a.id||'');
            const bId=String(b.id||'');
            const aGeneric=aId.toLowerCase().startsWith('garage_');
            const bGeneric=bId.toLowerCase().startsWith('garage_');

            // IDs personalizados primeiro; garage_* sempre no final.
            if(aGeneric!==bGeneric) return aGeneric?1:-1;

            // Mantém ordem alfabética dentro de cada grupo.
            return aId.localeCompare(bId,undefined,{numeric:true,sensitivity:'base'});
        });

        html=arr.map(g=>`<tr>
            <td>${esc(g.id)}</td>
            <td><span class="pill">${esc(g.type)}</span></td>
            <td>${g.permiss?esc(g.permiss):'<span class="muted">Livre</span>'}</td>
            <td>${g.spawnCoords?.length||0}</td>
            <td class="mono">${f(g.coords?.x)}, ${f(g.coords?.y)}, ${f(g.coords?.z)}</td>
            <td class="actions">${actions('garage',g.id,true)}</td>
        </tr>`).join('');
    }else if(module==='garages'){
        $('#page-title').textContent='Tipos de Garagem';
        $('#page-sub').textContent='Configure garagens públicas, de serviço, blips e veículos disponíveis.';
        $('#new').textContent='＋ Novo tipo';
        $('#stats').innerHTML=
            stat('Tipos cadastrados',garageTypes.length,'configurações disponíveis')+
            stat('Serviço',garageTypes.filter(t=>t.data?.type==='service').length,'com frota definida')+
            stat('Blip ativo',garageTypes.filter(t=>t.data?.blip?.showBlip).length,'visíveis no mapa');

        head='<tr><th>Tipo</th><th>Modo</th><th>Blip</th><th>Veículos / classes</th><th class="actions">Ações</th></tr>';

        let arr=garageTypes.filter(t=>!q||t.name.toLowerCase().includes(q)||String(t.data?.type).includes(q));
        arr.sort((a,b)=>a.name.localeCompare(b.name));

        html=arr.map(t=>{
            const d=t.data||{};
            const count=d.type==='service'?(d.vehicles?.length||0):Object.values(d.listCars||{}).filter(Boolean).length;
            return `<tr>
                <td>${esc(t.name)}</td>
                <td><span class="pill ${d.type==='service'?'green':''}">${esc(d.type)}</span></td>
                <td>${d.blip?.showBlip?esc(d.blip.name||'Garagem'):'<span class="muted">Oculto</span>'}</td>
                <td>${count}</td>
                <td class="actions">${actions('type',t.name,false)}</td>
            </tr>`;
        }).join('');
    }else if(module==='shops'){
        $('#page-title').textContent='Gerenciar Lojas';
        $('#page-sub').textContent='Configure compra, venda, itens, preços, permissões, blips e pontos físicos.';
        $('#new').textContent='＋ Nova loja';

        const totalPoints=shops.reduce((a,s)=>a+(s.data?.coords?.length||0),0);
        const totalItems=shops.reduce((a,s)=>a+Object.keys(s.data?.items||{}).length,0);

        $('#stats').innerHTML=
            stat('Lojas',shops.length,'configurações no JSON')+
            stat('Pontos físicos',totalPoints,'markers cadastrados')+
            stat('Itens configurados',totalItems,'produtos e valores');

        head='<tr><th>Loja</th><th>Modo</th><th>Permissão</th><th>Itens</th><th>Pontos</th><th>Blip</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=shops.filter(s=>{
            const d=s.data||{};
            const search=!q||s.name.toLowerCase().includes(q)||String(d.mode||'').includes(q)||String(d.perm||'').toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='buy'&&d.mode!=='sell')||
                (filter==='sell'&&d.mode==='sell')||
                (filter==='free'&&!d.perm)||
                (filter==='restricted'&&!!d.perm);
            return search&&contextual;
        });

        arr.sort((a,b)=>{
            if(sort==='mode')return String(a.data?.mode||'').localeCompare(String(b.data?.mode||''));
            if(sort==='items')return Object.keys(b.data?.items||{}).length-Object.keys(a.data?.items||{}).length;
            if(sort==='points')return (b.data?.coords?.length||0)-(a.data?.coords?.length||0);
            return a.name.localeCompare(b.name);
        });

        html=arr.map(s=>{
            const d=s.data||{};
            const first=d.coords?.[0]?.coords;
            return `<tr>
                <td>${esc(s.name)}</td>
                <td><span class="pill ${d.mode==='sell'?'green':''}">${d.mode==='sell'?'Venda':'Compra'}</span></td>
                <td>${d.perm?esc(d.perm):'<span class="muted">Livre</span>'}</td>
                <td>${Object.keys(d.items||{}).length}</td>
                <td>${d.coords?.length||0}</td>
                <td>${d.blip?esc(d.blip.text||'Ativo'):'<span class="muted">Sem blip</span>'}</td>
                <td class="actions">${actions('shop',s.name,!!first)}</td>
            </tr>`;
        }).join('');
    }else if(module==='craft'){
        const benches=craftSetups.benches||[];
        const farm=craftSetups.farm||{};
        $('#page-title').textContent='Craft + Farm';
        $('#page-sub').textContent='Crie bancadas e configure, no mesmo cadastro, os itens coletados pelo m_farm.';
        $('#new').textContent='＋ Nova bancada';
        const linked=benches.filter(b=>b.farmRewardType).length;
        $('#stats').innerHTML=stat('Bancadas',benches.length,'cadastradas no m_craft')+
            stat('Com farm',linked,'ligações ativas no m_farm')+
            stat('Receitas',benches.reduce((a,b)=>a+(b.craftItems?.length||0),0),'produtos configurados');
        head='<tr><th>Bancada</th><th>Craft</th><th>Armazém</th><th>Receitas</th><th>Farm</th><th>Pontos</th><th class="actions">Ações</th></tr>';
        const filter=$('#group-filter').value;
        let arr=benches.filter(b=>{
            const search=!q||String(b.name).toLowerCase().includes(q)||String(b.craftPermission||'').toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='withfarm'&&!!b.farmRewardType)||
                (filter==='nofarm'&&!b.farmRewardType)||
                (filter==='restricted'&&!!b.craftPermission);
            return search&&contextual;
        });
        arr.sort((a,b)=>{
            if(sort==='recipes')return (b.craftItems?.length||0)-(a.craftItems?.length||0);
            if(sort==='points')return (b.coords?.length||0)-(a.coords?.length||0);
            if(sort==='farm')return String(a.farmRewardType||'').localeCompare(String(b.farmRewardType||''));
            return String(a.name).localeCompare(String(b.name));
        });
        html=arr.map(b=>`<tr>
            <td>${esc(b.name)}</td>
            <td>${esc(b.craftPermission||'')}</td>
            <td>${esc(b.armazemPermission||'')}</td>
            <td>${b.craftItems?.length||0}</td>
            <td>${b.farmRewardType?`<span class="pill green">${esc(b.farmRewardType)}</span>`:'<span class="muted">Desativado</span>'}</td>
            <td>${b.coords?.length||0}</td>
            <td class="actions">${actions('craft',b.name,!!b.coords?.[0])}</td>
        </tr>`).join('');
    }else if(module==='cloakroom'){
        $('#page-title').textContent='Blip Fardamento';
        $('#page-sub').textContent='Gerencie locais, permissões e fardamentos capturados diretamente do personagem.';
        $('#new').textContent='＋ Novo Blip Fardamento';

        const uniformCount=cloakrooms.reduce((n,r)=>n+(r.uniforms?.length||0),0);
        $('#stats').innerHTML=
            stat('Locais',cloakrooms.length,'markers cadastrados')+
            stat('Fardamentos',uniformCount,'uniformes configurados')+
            stat('Configuração','JSON','m_cloakroom/config.json');

        head='<tr><th>Nome</th><th>Permissão</th><th>Fardamentos</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=cloakrooms.filter(r=>{
            const search=!q||String(r.name||'').toLowerCase().includes(q)||String(r.permission||'').toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='free'&&!r.permission)||
                (filter==='restricted'&&!!r.permission)||
                (filter==='withuniform'&&(r.uniforms?.length||0)>0);
            return search&&contextual;
        });
        arr.sort((a,b)=>{
            if(sort==='permission')return String(a.permission||'').localeCompare(String(b.permission||''));
            if(sort==='uniforms')return (b.uniforms?.length||0)-(a.uniforms?.length||0);
            return String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
        });

        html=arr.map(r=>`<tr>
            <td><b>${esc(r.name)}</b></td>
            <td>${r.permission?`<span class="pill">${esc(r.permission)}</span>`:'<span class="muted">Livre</span>'}</td>
            <td>${r.uniforms?.length||0}</td>
            <td class="mono">${f(r.coords?.x)}, ${f(r.coords?.y)}, ${f(r.coords?.z)}</td>
            <td class="actions">${actions('cloakroom',r.name,true)}</td>
        </tr>`).join('');
    }else if(module==='groups'){
        $('#page-title').textContent='Gerenciar Cargos';
        $('#page-sub').textContent='Crie, edite, renomeie e exclua cargos da vRP em tempo real.';
        $('#new').textContent='＋ Novo cargo';

        const allPerms=new Set();
        managedGroups.forEach(g=>(g.permissions||[]).forEach(p=>allPerms.add(p)));

        $('#stats').innerHTML=
            stat('Cargos',managedGroups.length,'carregados em groups.json')+
            stat('Permissões',allPerms.size,'permissões únicas em uso')+
            stat('Organizações',managedGroups.filter(g=>g.config?.gtype==='org').length,'cargos do tipo org');

        head='<tr><th>Cargo</th><th>Tipo</th><th>Organização</th><th>Salário</th><th>Permissões</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        const knownTypes=['staff','org','emp','dm'];

        let arr=managedGroups.filter(g=>{
            const type=String(g.config?.gtype||'');
            const matchesSearch=!q||
                String(g.name||'').toLowerCase().includes(q)||
                type.toLowerCase().includes(q)||
                String(g.config?.orgName||'').toLowerCase().includes(q)||
                (g.permissions||[]).some(p=>String(p).toLowerCase().includes(q));

            const matchesFilter=
                filter==='all'||
                type===filter||
                (filter==='other'&&!knownTypes.includes(type));

            return matchesSearch&&matchesFilter;
        });

        arr.sort((a,b)=>{
            if(sort==='type'){
                const ta=String(a.config?.gtype||'');
                const tb=String(b.config?.gtype||'');
                return ta.localeCompare(tb)||String(a.name).localeCompare(String(b.name));
            }

            if(sort==='salary'){
                return (Number(b.config?.salario)||0)-(Number(a.config?.salario)||0);
            }
            if(sort==='permissions'){
                return (b.permissions?.length||0)-(a.permissions?.length||0);
            }
            if(sort==='org'){
                const oa=groupOrgSortKey(a);
                const ob=groupOrgSortKey(b);

                return oa.localeCompare(ob,undefined,{sensitivity:'base'}) ||
                    String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
            }

            return String(a.name).localeCompare(String(b.name),undefined,{sensitivity:'base'});
        });

        html=arr.map(g=>`<tr>
            <td><b>${esc(g.name)}</b>${g.name==='user'?'<small class="rowid">cargo obrigatório</small>':''}</td>
            <td>${g.config?.gtype?`<span class="pill">${esc(groupTypeLabel(g.config.gtype))}</span>`:'<span class="muted">Sem tipo</span>'}</td>
            <td>${g.config?.orgName?esc(g.config.orgName):'<span class="muted">—</span>'}</td>
            <td>${g.config?.salario!=null?`R$ ${Number(g.config.salario).toLocaleString('pt-BR')}`:'<span class="muted">—</span>'}</td>
            <td><span class="permission-count">${(g.permissions||[]).length}</span></td>
            <td class="actions">${actions('group',g.name,false)}</td>
        </tr>`).join('');
    }else if(module==='mapmarkings'){
        $('#page-title').textContent='Marcações Mapa';
        $('#page-sub').textContent='Cadastre e edite os blips exibidos no mapa sem alterar código.';
        $('#new').textContent='＋ Nova marcação';

        $('#stats').innerHTML=
            stat('Marcações',mapMarkings.length,'blips cadastrados')+
            stat('Sprites',new Set(mapMarkings.map(x=>x.sprite)).size,'tipos visuais em uso')+
            stat('Configuração','JSON','m_snippets/config/blips.json');

        head='<tr><th>Ícone</th><th>Nome</th><th>Sprite</th><th>Cor</th><th>Escala</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=mapMarkings.filter(x=>{
            const search=!q||String(x.name||'').toLowerCase().includes(q)||String(x.sprite||'').includes(q)||String(x.color||'').includes(q);
            const contextual=filter==='all'||(filter.startsWith('color:')&&String(x.color)===filter.slice(6));
            return search&&contextual;
        });

        arr.sort((a,b)=>{
            if(sort==='sprite')return (Number(a.sprite)||0)-(Number(b.sprite)||0);
            if(sort==='color')return (Number(a.color)||0)-(Number(b.color)||0);
            if(sort==='scale')return (Number(b.scale)||0)-(Number(a.scale)||0);
            return String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
        });

        html=arr.map(x=>`<tr>
            <td class="mapblipcell">${mapBlipIcon(x.sprite)}</td>
            <td>
                <b>${esc(x.name)}</b>
                <small class="rowid">${esc(x.id)}</small>
            </td>
            <td><span class="pill">${esc(x.sprite)}</span></td>
            <td>${esc(x.color)}</td>
            <td>${Number(x.scale||0).toFixed(2)}</td>
            <td class="mono">${f(x.coords?.x)}, ${f(x.coords?.y)}, ${f(x.coords?.z)}</td>
            <td class="actions">${actions('mapmarking',x.id,true)}</td>
        </tr>`).join('');
    }else if(module==='dealership'){
        const imageBase=String(dealershipData.settings?.imagesDir||'http://127.0.0.1/vrp_images/');

        if(dealershipView==='server'){
            $('#page-title').textContent='Veículos cadastrados servidor';
            $('#page-sub').textContent='Catálogo completo do m_garage / shared-side/listcars.json. Edite ou exclua veículos do servidor em tempo real.';
            $('#new').textContent='＋ Cadastrar veículo concessionária';

            const vehicles=Object.entries(serverVehicleCatalog||{}).map(([spawn,data])=>({spawn,...data}));
            const bannedCount=vehicles.filter(v=>v.banned===true).length;
            const types=new Set(vehicles.map(v=>v.type).filter(Boolean));

            $('#stats').innerHTML=
                stat('Veículos servidor',vehicles.length,'cadastrados no listcars.json')+
                stat('Tipos',types.size,'tipos diferentes')+
                stat('Bloqueados',bannedCount,'veículos com banned ativo');

            head=serverVehicleBulkMode
                ?'<tr><th class="bulk-check-col"><input id="server-bulk-check-visible" type="checkbox" title="Selecionar todos os resultados visíveis"></th><th>Imagem</th><th>Veículo</th><th>Tipo</th><th>Valor</th><th>Porta-malas</th><th>Status</th><th class="actions">Ações</th></tr>'
                :'<tr><th>Imagem</th><th>Veículo</th><th>Tipo</th><th>Valor</th><th>Porta-malas</th><th>Status</th><th class="actions">Ações</th></tr>';

            const filter=$('#group-filter').value;
            let arr=vehicles.filter(v=>{
                const search=!q||
                    String(v.name||'').toLowerCase().includes(q)||
                    String(v.spawn||'').toLowerCase().includes(q)||
                    String(v.model||'').toLowerCase().includes(q)||
                    String(v.type||'').toLowerCase().includes(q);

                const contextual=filter==='all'||
                    (filter==='banned'&&v.banned===true)||
                    (filter==='available'&&v.banned!==true)||
                    (filter.startsWith('type:')&&String(v.type||'outros')===filter.slice(5));

                return search&&contextual;
            });

            arr.sort((a,b)=>{
                if(sort==='spawn')return String(a.spawn).localeCompare(String(b.spawn),undefined,{sensitivity:'base'});
                if(sort==='type')return String(a.type||'').localeCompare(String(b.type||''))||String(a.name||'').localeCompare(String(b.name||''));
                if(sort==='price')return (Number(b.price)||0)-(Number(a.price)||0);
                if(sort==='trunk')return (Number(b.trunk)||0)-(Number(a.trunk)||0);
                return String(a.name||a.spawn).localeCompare(String(b.name||b.spawn),undefined,{sensitivity:'base'});
            });

            serverVehicleVisibleSpawns=arr.map(v=>v.spawn);
            html=arr.map(v=>`<tr class="${serverVehicleBulkSelection.has(v.spawn)?'bulk-selected':''}">
                ${serverVehicleBulkMode?`<td class="bulk-check-col"><input class="server-bulk-check" type="checkbox" data-server-select="${enc(v.spawn)}" ${serverVehicleBulkSelection.has(v.spawn)?'checked':''}></td>`:''}
                <td><div class="dealership-car-thumb"><img src="${esc(imageBase+v.spawn+'.png')}" onerror="this.style.display='none'" alt=""></div></td>
                <td><b>${esc(v.name||v.spawn)}</b><small class="rowid">${esc(v.spawn)}</small></td>
                <td><span class="pill">${esc(v.type||'outros')}</span></td>
                <td>R$ ${Number(v.price||0).toLocaleString('pt-BR')}</td>
                <td>${Number(v.trunk)||0} kg</td>
                <td>${v.banned?'<span class="pill danger-soft">Bloqueado</span>':'<span class="pill">Liberado</span>'}</td>
                <td class="actions">
                    ${serverVehicleBulkMode
                        ?'<span class="muted">Selecione</span>'
                        :`<button class="rowbtn edit" data-server-edit="${enc(v.spawn)}" title="Editar">✎</button>
                         <button class="rowbtn del" data-server-delete="${enc(v.spawn)}" title="Excluir">×</button>`}
                </td>
            </tr>`).join('');
        }else{
            $('#page-title').textContent='Concessionária';
            $('#page-sub').textContent='O catálogo do servidor vem do m_garage; a concessionária controla apenas quais veículos vende e o estoque.';
            $('#new').textContent='＋ Cadastrar veículo concessionária';

            const runtime=dealershipData.runtimeVehicles||{};
            const vehicles=Object.entries(dealershipData.vehicles||{}).map(([spawn,state])=>({
                spawn,
                stock:Number(state.stock)||0,
                amountSell:Number(state.amountSell)||0,
                ...(runtime[spawn]||serverVehicleCatalog[spawn]||{})
            }));

            const totalStock=vehicles.reduce((n,v)=>n+(Number(v.stock)||0),0);
            const categories=new Set(vehicles.map(v=>v.category).filter(Boolean));

            $('#stats').innerHTML=
                stat('Na concessionária',vehicles.length,'veículos cadastrados para venda')+
                stat('Estoque total',totalStock,'unidades disponíveis')+
                stat('Catálogo servidor',Object.keys(serverVehicleCatalog||{}).length,'veículos no m_garage');

            head='<tr><th>Imagem</th><th>Veículo</th><th>Categoria</th><th>Valor</th><th>Estoque</th><th>Porta-malas</th><th class="actions">Ações</th></tr>';

            const filter=$('#group-filter').value;
            let arr=vehicles.filter(v=>{
                const search=!q||
                    String(v.name||v.spawn).toLowerCase().includes(q)||
                    String(v.spawn||'').toLowerCase().includes(q)||
                    String(v.category||v.type||'').toLowerCase().includes(q);
                const contextual=filter==='all'||
                    (filter==='stock'&&(Number(v.stock)||0)>0)||
                    (filter==='nostock'&&(Number(v.stock)||0)<=0)||
                    (filter.startsWith('category:')&&String(v.category)===filter.slice(9));
                return search&&contextual;
            });

            arr.sort((a,b)=>{
                if(sort==='spawn')return String(a.spawn).localeCompare(String(b.spawn),undefined,{sensitivity:'base'});
                if(sort==='category')return String(a.category||'').localeCompare(String(b.category||''))||String(a.name||'').localeCompare(String(b.name||''));
                if(sort==='price')return (Number(b.price)||0)-(Number(a.price)||0);
                if(sort==='stock')return (Number(b.stock)||0)-(Number(a.stock)||0);
                if(sort==='trunk')return (Number(b.trunk)||0)-(Number(a.trunk)||0);
                return String(a.name||a.spawn).localeCompare(String(b.name||b.spawn),undefined,{sensitivity:'base'});
            });

            html=arr.map(v=>`<tr>
                <td><div class="dealership-car-thumb"><img src="${esc(imageBase+v.spawn+'.png')}" onerror="this.style.display='none'" alt=""></div></td>
                <td><b>${esc(v.name||v.spawn)}</b><small class="rowid">${esc(v.spawn)}</small></td>
                <td><span class="pill">${esc(v.category||v.type||'outros')}</span></td>
                <td>R$ ${Number(v.price||0).toLocaleString('pt-BR')}</td>
                <td>${Number(v.stock)||0}</td>
                <td>${Number(v.trunk)||0} kg</td>
                <td class="actions">${actions('dealershipvehicle',v.spawn,false)}</td>
            </tr>`).join('');
        }

    }else if(module==='mansions'){
        $('#page-title').textContent='Mansões';
        $('#page-sub').textContent='Cadastre mansões compráveis com cargo, baú, garagem, trancas, vale, IPTU e limite de moradores.';
        $('#new').textContent='＋ Nova mansão';

        const list=mansionsData.mansions||[];
        const occupied=list.filter(x=>x.ownerId).length;
        const free=list.length-occupied;
        const residents=list.reduce((n,x)=>n+(Number(x.occupiedCount)||0),0);

        $('#stats').innerHTML=
            stat('Mansões',list.length,'cadastradas')+
            stat('Disponíveis / Ocupadas',`${free} / ${occupied}`,'situação atual')+
            stat('Moradores',residents,'incluindo proprietários');

        head='<tr><th>Mansão</th><th>Cargo / Permissão</th><th>Valor / Vale</th><th>Moradores</th><th>Status</th><th>Recursos</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=list.filter(x=>{
            const search=!q||String(x.name||'').toLowerCase().includes(q)||String(x.group||'').toLowerCase().includes(q)||String(x.permission||'').toLowerCase().includes(q)||String(x.voucher||'').toLowerCase().includes(q);
            const contextual=filter==='all'||(filter==='free'&&!x.ownerId)||(filter==='occupied'&&!!x.ownerId);
            return search&&contextual;
        });

        arr.sort((a,b)=>{
            if(sort==='price')return (Number(b.price)||0)-(Number(a.price)||0);
            if(sort==='residents')return (Number(b.occupiedCount)||0)-(Number(a.occupiedCount)||0);
            return String(a.name||'').localeCompare(String(b.name||''),undefined,{numeric:true,sensitivity:'base'});
        });

        html=arr.map(x=>{
            const resources=[x.chest?.enabled?'Baú':null,x.garage?.enabled?'Garagem':null,(x.doors?.length||0)?`${x.doors.length} tranca(s)`:null].filter(Boolean);
            const owner=(x.residents||[]).find(r=>r.owner);
            return `<tr>
                <td><b>${esc(x.name)}</b><small class="rowid">${esc(x.id)}</small></td>
                <td><b>${esc(x.group)}</b><small class="rowid">${esc(x.permission)}</small></td>
                <td><b>R$ ${Number(x.price||0).toLocaleString('pt-BR')}</b><small class="rowid">${esc(x.voucher)}</small><small class="rowid">IPTU: R$ ${Number(x.iptuValue||0).toLocaleString('pt-BR')} / 20 dias</small></td>
                <td>${Number(x.occupiedCount)||0} / ${Number(x.maxResidents)||1}</td>
                <td>${x.ownerId?`<span class="pill green">Ocupada</span><small class="rowid">${esc(owner?.name||('ID '+x.ownerId))}</small>`:'<span class="pill">Disponível</span>'}</td>
                <td>${resources.length?resources.map(v=>`<span class="pill mansion-resource-pill">${esc(v)}</span>`).join(' '):'<span class="muted">Nenhum</span>'}</td>
                <td class="actions">${actions('mansion',x.id,true)}</td>
            </tr>`;
        }).join('');
    }else if(module==='houses'){
        $('#page-title').textContent='Casas';
        $('#page-sub').textContent='Crie e edite residências, apartamentos, interiores e valores diretamente pelo painel.';
        $('#new').textContent='＋ Nova residência';

        const homes=residencesData.residences||[];
        const interiors=residencesData.interiors||{};
        const houses=homes.filter(x=>x.type!=='Apartamento').length;
        const apartments=homes.filter(x=>x.type==='Apartamento').length;

        $('#stats').innerHTML=
            stat('Residências',homes.length,'pontos cadastrados')+
            stat('Casas / Apartamentos',`${houses} / ${apartments}`,'tipos cadastrados')+
            stat('Interiores',Object.keys(interiors).length,'modelos disponíveis');

        head='<tr><th>Residência</th><th>Tipo</th><th>Interior</th><th>Valor</th><th>Local</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=homes.filter(x=>{
            const search=!q||String(x.name||'').toLowerCase().includes(q)||String(x.type||'').toLowerCase().includes(q)||String(x.interior||'').toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='house'&&x.type!=='Apartamento')||
                (filter==='apartment'&&x.type==='Apartamento')||
                (filter.startsWith('interior:')&&String(x.interior)===filter.slice(9));
            return search&&contextual;
        });

        arr.sort((a,b)=>{
            if(sort==='type')return String(a.type||'').localeCompare(String(b.type||''))||String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
            if(sort==='interior')return String(a.interior||'').localeCompare(String(b.interior||''))||String(a.name||'').localeCompare(String(b.name||''));
            if(sort==='price')return (Number(b.price)||0)-(Number(a.price)||0);
            return String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
        });

        html=arr.map(x=>`<tr>
            <td><b>${esc(x.name)}</b>${x.type==='Apartamento'?`<small class="rowid">${Number(x.slot)||1} unidades</small>`:''}</td>
            <td><span class="pill">${esc(x.type||'Casa')}</span></td>
            <td>${esc(x.interior||'')}</td>
            <td>R$ ${Number(x.price||0).toLocaleString('pt-BR')}</td>
            <td class="mono">${f(x.x)}, ${f(x.y)}, ${f(x.z)}</td>
            <td class="actions">${actions('residence',x.name,true)}</td>
        </tr>`).join('');
    }else if(module==='robberies'){
        $('#page-title').textContent='Roubos';
        $('#page-sub').textContent='Configure separadamente cada sistema de roubo conectado ao painel.';
        $('#new').classList.add('hidden');

        const locs=robberiesData.locations||[];
        const types=Object.keys(robberiesData.setups||{});
        $('#stats').innerHTML=
            stat('Scripts',4,'resources conectados')+
            stat('Tipos',types.length,'tipos de roubo')+
            stat('Locais',locs.length,'pontos configurados');

        head='<tr><th>Sistema</th><th>Resource</th><th>Tipos</th><th>Locais</th><th>Status</th><th class="actions">Ações</th></tr>';
        html=`<tr>
            <td><b>Roubos de Comércio</b><div class="muted">Lojas, registradoras, caixas e AmmuNation</div></td>
            <td class="mono">m_roubos</td>
            <td>${types.length}</td>
            <td>${locs.length}</td>
            <td><span class="pill">Conectado</span></td>
            <td class="actions"><button class="rowbtn edit" data-a="rob-open" title="Configurar">✎</button></td>
        </tr>
        <tr>
            <td><b>Banco Central</b><div class="muted">Portas, cofres, dinheiro, hacking e itens</div></td>
            <td class="mono">m_banco_central</td>
            <td>${(bancoCentralData.banks||[]).length} banco</td>
            <td>${(bancoCentralData.banks?.[0]?.doors||[]).length} portas</td>
            <td><span class="pill">Conectado</span></td>
            <td class="actions"><button class="rowbtn edit" data-a="bank-open" title="Configurar">✎</button></td>
        </tr>
        <tr>
            <td><b>Joalheria</b><div class="muted">Hack, C4, vitrines, recompensas e polícia</div></td>
            <td class="mono">m_joalheria</td>
            <td>${(joalheriaData.displays||[]).length} vitrines</td>
            <td>${(joalheriaData.rewards||[]).length} recompensas</td>
            <td><span class="pill">Conectado</span></td>
            <td class="actions"><button class="rowbtn edit" data-a="jewelry-open" title="Configurar">✎</button></td>
        </tr>
        <tr>
            <td><b>Roubo a Cofres</b><div class="muted">Fleeca, cofres, hacking, recompensa e drops</div></td>
            <td class="mono">m_roubocofre</td>
            <td>${Object.keys(roubocofreData.banks||{}).length} bancos</td>
            <td>${roubocofreData.settings?.rewardMin??0}–${roubocofreData.settings?.rewardMax??0}</td>
            <td><span class="pill">Conectado</span></td>
            <td class="actions"><button class="rowbtn edit" data-a="vault-open" title="Configurar">✎</button></td>
        </tr>`;

        const robFilter=$('#group-filter').value;
        const orderMap={
            commerce:{name:'Roubos de Comércio',resource:'m_roubos'},
            central:{name:'Banco Central',resource:'m_banco_central'},
            jewelry:{name:'Joalheria',resource:'m_joalheria'},
            vault:{name:'Roubo a Cofres',resource:'m_roubocofre'}
        };
        const temp=document.createElement('tbody');
        temp.innerHTML=html;
        const keys=['commerce','central','jewelry','vault'];
        let rows=[...temp.querySelectorAll('tr')].map((row,i)=>({key:keys[i],row}));
        if(robFilter!=='all')rows=rows.filter(x=>x.key===robFilter);
        rows.sort((a,b)=>{
            const prop=sort==='resource'?'resource':'name';
            return orderMap[a.key][prop].localeCompare(orderMap[b.key][prop],undefined,{sensitivity:'base'});
        });
        html=rows.map(x=>x.row.outerHTML).join('');
    }else if(module==='jobs'){
        $('#page-title').textContent='Gerenciar Empregos';
        $('#page-sub').textContent='Edite níveis, pagamentos, locais, uniformes e configurações específicas em tempo real.';

        const entries=Object.entries(jobsData.jobs||{}).map(([name,data])=>({name,data,extra:jobsData.extras?.[name]||{}}));
        const uniformCount=entries.filter(x=>Object.keys(x.data.uniforme||{}).length>0).length;
        const totalLevels=entries.reduce((n,x)=>n+(Number(x.data.total_nivel)||0),0);

        $('#stats').innerHTML=
            stat('Empregos',entries.length,'cadastrados no jobs.json')+
            stat('Níveis',totalLevels,'níveis configurados')+
            stat('Com uniforme',uniformCount,'uniformes definidos');

        head='<tr><th>Emprego</th><th>Local inicial</th><th>Níveis</th><th>Pagamento</th><th>Uniforme</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=entries.filter(x=>{
            const hasUniform=Object.keys(x.data.uniforme||{}).length>0;
            const search=!q||x.name.toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='uniform'&&hasUniform)||
                (filter==='nouniform'&&!hasUniform)||
                (filter==='multilevel'&&(Number(x.data.total_nivel)||0)>1);
            return search&&contextual;
        });
        arr.sort((a,b)=>{
            if(sort==='levels')return (Number(b.data.total_nivel)||0)-(Number(a.data.total_nivel)||0);
            if(sort==='payment')return (b.data.payment_for_level?.length||0)-(a.data.payment_for_level?.length||0);
            if(sort==='uniform')return Object.keys(b.data.uniforme||{}).length-Object.keys(a.data.uniforme||{}).length;
            return a.name.localeCompare(b.name,undefined,{sensitivity:'base'});
        });

        html=arr.map(x=>{
            const pays=Array.isArray(x.data.payment_for_level)?x.data.payment_for_level:[];
            const hasPay=pays.length>0;
            const uniforms=x.data.uniforme||{};
            const sexes=[uniforms.masculino?'M':'',uniforms.feminino?'F':''].filter(Boolean).join(' / ');

            return `<tr>
                <td><b>${esc(x.name)}</b></td>
                <td class="mono">${f(x.data.inicio?.[0])}, ${f(x.data.inicio?.[1])}, ${f(x.data.inicio?.[2])}</td>
                <td>${Number(x.data.total_nivel)||0}</td>
                <td>${hasPay?`${pays.length} níveis`:'<span class="muted">Específico do emprego</span>'}</td>
                <td>${sexes?`<span class="pill">${sexes}</span>`:'<span class="muted">Não definido</span>'}</td>
                <td class="actions">${actions('job',x.name,true)}</td>
            </tr>`;
        }).join('');
    }else if(module==='safezone'){
        $('#page-title').textContent='Gerenciar SafeZones';
        $('#page-sub').textContent='Crie e edite áreas seguras poligonais diretamente pelo jogo.';
        $('#new').textContent='＋ Nova SafeZone';

        const totalPolygons=safeZones.reduce((n,z)=>n+(z.zones?.length||0),0);
        const totalPoints=safeZones.reduce((n,z)=>n+(z.zones||[]).reduce((x,p)=>x+(p.coords?.length||0),0),0);

        $('#stats').innerHTML=
            stat('SafeZones',safeZones.length,'áreas cadastradas')+
            stat('Polígonos',totalPolygons,'áreas PolyZone')+
            stat('Pontos',totalPoints,'vértices configurados');

        head='<tr><th>SafeZone</th><th>Polígonos</th><th>Pontos</th><th>Altura</th><th>Debug</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        const zonePoints=z=>(z.zones||[]).reduce((n,p)=>n+(p.coords?.length||0),0);
        const zoneHeight=z=>{
            const polys=z.zones||[];
            if(!polys.length)return 0;
            return Math.max(...polys.map(p=>Number(p.maxZ)||0))-Math.min(...polys.map(p=>Number(p.minZ)||0));
        };
        let arr=safeZones.filter(z=>{
            const search=!q||String(z.name||'').toLowerCase().includes(q);
            const contextual=filter==='all'||
                (filter==='debug'&&z.debug)||
                (filter==='nodebug'&&!z.debug)||
                (filter==='multi'&&(z.zones?.length||0)>1);
            return search&&contextual;
        });
        arr.sort((a,b)=>{
            if(sort==='polygons')return (b.zones?.length||0)-(a.zones?.length||0);
            if(sort==='points')return zonePoints(b)-zonePoints(a);
            if(sort==='height')return zoneHeight(b)-zoneHeight(a);
            return String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
        });

        html=arr.map(z=>{
            const polys=z.zones||[];
            const points=polys.reduce((n,p)=>n+(p.coords?.length||0),0);
            const min=polys.length?Math.min(...polys.map(p=>Number(p.minZ)||0)):0;
            const max=polys.length?Math.max(...polys.map(p=>Number(p.maxZ)||0)):0;

            return `<tr>
                <td><b>${esc(z.name)}</b></td>
                <td>${polys.length}</td>
                <td>${points}</td>
                <td class="mono">${f(min)} → ${f(max)}</td>
                <td>${z.debug?'<span class="pill">Ativo</span>':'<span class="muted">Desativado</span>'}</td>
                <td class="actions">${actions('safezone',z.name,true)}</td>
            </tr>`;
        }).join('');
    }else if(module==='desmanche'){
        $('#page-title').textContent='Gerenciar Desmanches';
        $('#page-sub').textContent='Cadastre locais, permissões, itens e etapas do desmanche sem alterar código.';
        $('#new').textContent='＋ Novo desmanche';

        $('#stats').innerHTML=
            stat('Desmanches',desmanches.length,'locais cadastrados')+
            stat('Veículo comum',`${Math.round((Number(desmancheSettings.porcentagem_veiculocomum)||0)*100)}%`,'percentual do valor pago')+
            stat('Veículo VIP',`${Math.round((Number(desmancheSettings.porcentagem_veiculovip)||0)*100)}%`,'percentual do valor pago');

        head='<tr><th>Desmanche</th><th>Permissão</th><th>Item</th><th>Início</th><th class="actions">Ações</th></tr>';

        const filter=$('#group-filter').value;
        let arr=desmanches.filter(d=>{
            const search=!q||String(d.name||'').toLowerCase().includes(q)||String(d.permissao||'').toLowerCase().includes(q);
            const contextual=filter==='all'||(filter==='item'&&d.precisa_de_item)||(filter==='noitem'&&!d.precisa_de_item);
            return search&&contextual;
        });

        arr.sort((a,b)=>{
            if(sort==='permission')return String(a.permissao||'').localeCompare(String(b.permissao||''));
            if(sort==='item')return Number(!!b.precisa_de_item)-Number(!!a.precisa_de_item);
            return String(a.name||'').localeCompare(String(b.name||''),undefined,{sensitivity:'base'});
        });

        html=arr.map(d=>{
            const items=(d.itens_necessarios||[])
                .map(i=>`${esc(i.qtd)}x ${esc(i.item)}`)
                .join(', ');

            return `<tr>
                <td><b>${esc(d.name)}</b></td>
                <td><span class="pill">${esc(d.permissao||'')}</span></td>
                <td>${d.precisa_de_item?items:'<span class="muted">Não exige item</span>'}</td>
                <td class="mono">${f(d.inicio?.x)}, ${f(d.inicio?.y)}, ${f(d.inicio?.z)}</td>
                <td class="actions">${actions('desmanche',d.name,true)}</td>
            </tr>`;
        }).join('');
    }else if(module==='clothing'){
        $('#page-title').textContent='Loja de Roupa';
        $('#page-sub').textContent='Cadastre, mova, confira e remova os pontos das lojas de roupa.';
        $('#new').textContent='＋ Novo local';
        $('#stats').innerHTML=
            stat('Locais',clothingShops.length,'pontos cadastrados')+
            stat('Configuração','JSON','localesSkinshop.json')+
            stat('Sincronização','Ativa','atualização em tempo real');
        head='<tr><th>ID</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';
        let arr=clothingShops.filter(s=>!q||String(s.id).includes(q)||`${s.coords?.x} ${s.coords?.y} ${s.coords?.z}`.includes(q));
        arr.sort((a,b)=>sort==='x'?(Number(a.coords?.x)||0)-(Number(b.coords?.x)||0):(+a.id||0)-(+b.id||0));
        html=arr.map(s=>`<tr>
            <td><div class="location-id-cell">${mapBlipIcon(73,'location-blip-icon')}<b>#${esc(s.id)}</b></div></td>
            <td class="mono">${f(s.coords?.x)}, ${f(s.coords?.y)}, ${f(s.coords?.z)}</td>
            <td class="actions">${actions('clothing',String(s.id),true)}</td>
        </tr>`).join('');
    }else if(module==='barbershop'){
        $('#page-title').textContent='Barbearia';
        $('#page-sub').textContent='Cadastre, mova, confira e remova os pontos das barbearias.';
        $('#new').textContent='＋ Novo local';
        $('#stats').innerHTML=
            stat('Locais',barbershops.length,'pontos cadastrados')+
            stat('Configuração','JSON','shared.locations.json')+
            stat('Sincronização','Ativa','atualização em tempo real');
        head='<tr><th>ID</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';
        let arr=barbershops.filter(s=>!q||String(s.id).includes(q)||`${s.coords?.x} ${s.coords?.y} ${s.coords?.z}`.includes(q));
        arr.sort((a,b)=>sort==='x'?(Number(a.coords?.x)||0)-(Number(b.coords?.x)||0):(+a.id||0)-(+b.id||0));
        html=arr.map(s=>`<tr>
            <td><div class="location-id-cell">${mapBlipIcon(71,'location-blip-icon')}<b>#${esc(s.id)}</b></div></td>
            <td class="mono">${f(s.coords?.x)}, ${f(s.coords?.y)}, ${f(s.coords?.z)}</td>
            <td class="actions">${actions('barbershop',String(s.id),true)}</td>
        </tr>`).join('');
    }else if(module==='tattoo'){
        $('#page-title').textContent='Estúdio Tattoo';
        $('#page-sub').textContent='Cadastre, mova, confira e remova os pontos dos estúdios de tatuagem.';
        $('#new').textContent='＋ Novo local';
        $('#stats').innerHTML=
            stat('Locais',tattooShops.length,'pontos cadastrados')+
            stat('Configuração','JSON','shared/locations.json')+
            stat('Sincronização','Ativa','atualização em tempo real');
        head='<tr><th>ID</th><th>Coordenadas</th><th class="actions">Ações</th></tr>';

        let arr=tattooShops.filter(s=>
            !q ||
            String(s.id).includes(q) ||
            `${s.coords?.x} ${s.coords?.y} ${s.coords?.z}`.includes(q)
        );

        arr.sort((a,b)=>sort==='x'?(Number(a.coords?.x)||0)-(Number(b.coords?.x)||0):(+a.id||0)-(+b.id||0));

        html=arr.map(s=>`<tr>
            <td><div class="location-id-cell">${mapBlipIcon(75,'location-blip-icon')}<b>#${esc(s.id)}</b></div></td>
            <td class="mono">${f(s.coords?.x)}, ${f(s.coords?.y)}, ${f(s.coords?.z)}</td>
            <td class="actions">${actions('tattoo',String(s.id),true)}</td>
        </tr>`).join('');
    }

    $('#thead').innerHTML=head;
    $('#tbody').innerHTML=html;
    $('#empty').classList.toggle('hidden',!!html);
}

function openDrawer(kind,item=null){
    editing=item;
    $('#overlay').classList.remove('hidden');
    $('#drawer').classList.add('open');
    $('#drawer-kicker').textContent=item?'EDITANDO CADASTRO':'NOVO CADASTRO';

    if(kind==='chest') chestForm(item);
    if(kind==='garage') garageForm(item);
    if(kind==='type') typeForm(item);
    if(kind==='shop') shopForm(item);
    if(kind==='craft') craftForm(item);
    if(kind==='clothing') clothingForm(item);
    if(kind==='barbershop') barbershopForm(item);
    if(kind==='tattoo') tattooForm(item);
    if(kind==='cloakroom') cloakroomForm(item);
    if(kind==='mapmarking') mapMarkingForm(item);
    if(kind==='group') groupForm(item);
    if(kind==='fac') facForm();
    if(kind==='desmanche') desmancheForm(item);
    if(kind==='safezone') safeZoneForm(item);
    if(kind==='job') jobForm(item);
    if(kind==='residence') residenceForm(item);
    if(kind==='mansion') mansionForm(item);
    if(kind==='dealershipvehicle') dealershipVehicleForm(item);
}

function closeDrawer(){
    $('#drawer').classList.remove('open');
    $('#overlay').classList.add('hidden');
    editing=null;
}

function coordsBlock(prefix,c){
    return `<div class="sectiontitle"><div><b>Posição</b><span>Local onde o marker ficará.</span></div><button type="button" id="${prefix}-pos" class="btn ghost mini">⌖ Usar minha posição</button></div>
    <div class="grid3">
        <label class="field"><span>X</span><input id="${prefix}-x" type="number" step="0.01" value="${c?.x??''}" required></label>
        <label class="field"><span>Y</span><input id="${prefix}-y" type="number" step="0.01" value="${c?.y??''}" required></label>
        <label class="field"><span>Z</span><input id="${prefix}-z" type="number" step="0.01" value="${c?.z??''}" required></label>
    </div>`;
}

function bindPosition(prefix){
    $(`#${prefix}-pos`).onclick=async()=>{
        const r=await nui('getPosition');
        if(!r.ok)return toast(r.message||'Não foi possível capturar a posição.','error');
        $(`#${prefix}-x`).value=r.coords.x;
        $(`#${prefix}-y`).value=r.coords.y;
        $(`#${prefix}-z`).value=r.coords.z;
    };
}

function chestForm(c){
    $('#drawer-title').textContent=c?c.name:'Cadastrar baú';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field"><span>Nome do baú</span><input id="c-name" value="${esc(c?.name||'')}" ${c?'disabled':''} required></label>
        <div class="grid2">
            <label class="field"><span>Peso máximo</span><input id="c-weight" type="number" min="1" value="${c?.weight??''}" required></label>
            <label class="field"><span>Permissão</span><input id="c-perm" value="${esc(c?.permission||'')}" placeholder="perm.policia"></label>
        </div>
        ${coordsBlock('c',c?.coords)}
        <div class="formactions"><button type="button" class="btn ghost cancel">Cancelar</button><button class="btn primary">Salvar baú</button></div>
    </form>`;

    bindPosition('c');
    $('.cancel').onclick=closeDrawer;
    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const data={
            name:c?.name||$('#c-name').value.trim(),
            weight:+$('#c-weight').value,
            permission:$('#c-perm').value.trim(),
            coords:{x:+$('#c-x').value,y:+$('#c-y').value,z:+$('#c-z').value}
        };
        await save(c?'updateChest':'createChest',data);
    };
}

function spawnRow(s={}){
    return `<div class="spawnrow">
        <input class="sx" type="number" step="0.01" value="${s.x??''}" placeholder="X">
        <input class="sy" type="number" step="0.01" value="${s.y??''}" placeholder="Y">
        <input class="sz" type="number" step="0.01" value="${s.z??''}" placeholder="Z">
        <input class="sw" type="number" step="0.01" value="${s.w??''}" placeholder="Heading">
        <button type="button" class="remove">×</button>
    </div>`;
}

function garageForm(g){
    $('#drawer-title').textContent=g?`Editar ${g.id}`:'Cadastrar garagem';

    const typeOptions=garageTypes.map(t=>`<option value="${esc(t.name)}" ${g?.type===t.name?'selected':''}>${esc(t.name)}</option>`).join('');

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field"><span>Identificador</span><input id="g-id" value="${esc(g?.id||'')}" required></label>
        ${g?`<div class="hint">Você pode renomear o identificador desta garagem. Ex.: <b>${esc(g.id)}</b> → <b>PublicaHelipa</b>.</div>`:''}
        <div class="grid2">
            <label class="field"><span>Tipo da garagem</span><select id="g-type" required><option value="">Selecione...</option>${typeOptions}</select></label>
            <label class="field"><span>Distância do marker</span><input id="g-distance" type="number" min="0.1" step="0.1" value="${g?.blipDistance??5}"></label>
        </div>
        <label class="field"><span>Permissão</span><input id="g-perm" value="${esc(g?.permiss||'')}" placeholder="Deixe vazio para acesso livre"></label>
        ${coordsBlock('g',g?.coords)}
        <div class="sectiontitle">
            <div><b>Vagas de saída</b><span>Posição + direção em que o veículo aparecerá.</span></div>
            <div class="sectionbuttons">
                <button type="button" id="capture-spawn" class="btn primary mini">⌖ Definir posição no jogo</button>
                <button type="button" id="add-spawn" class="btn ghost mini">＋ Manual</button>
            </div>
        </div>
        <div id="spawns">${(g?.spawnCoords||[]).map(spawnRow).join('')}</div>
        <div class="hint">No modo de posicionamento, fique exatamente onde o veículo deve nascer, olhe para a direção desejada e pressione E.</div>
        <div class="formactions"><button type="button" class="btn ghost cancel">Cancelar</button><button class="btn primary">Salvar garagem</button></div>
    </form>`;

    bindPosition('g');
    $('.cancel').onclick=closeDrawer;

    const bindRemove=()=>$$('#spawns .remove').forEach(b=>b.onclick=()=>b.closest('.spawnrow').remove());
    bindRemove();

    $('#add-spawn').onclick=()=>{
        $('#spawns').insertAdjacentHTML('beforeend',spawnRow());
        bindRemove();
    };

    $('#capture-spawn').onclick=async()=>{
        const r=await nui('startSpawnPosition');
        if(!r.ok)toast(r.message||'Não foi possível iniciar o posicionamento.','error');
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const spawnCoords=$$('#spawns .spawnrow').map(r=>({
            x:+r.querySelector('.sx').value,
            y:+r.querySelector('.sy').value,
            z:+r.querySelector('.sz').value,
            w:+r.querySelector('.sw').value
        })).filter(c=>Number.isFinite(c.x)&&Number.isFinite(c.y)&&Number.isFinite(c.z)&&Number.isFinite(c.w));

        const data={
            id:$('#g-id').value.trim(),
            originalId:g?.id,
            type:$('#g-type').value,
            blipDistance:+$('#g-distance').value,
            permiss:$('#g-perm').value.trim(),
            coords:{x:+$('#g-x').value,y:+$('#g-y').value,z:+$('#g-z').value},
            spawnCoords
        };

        await save(g?'updateGarage':'createGarage',data);
    };
}

function typeForm(t){
    const d=t?.data||{};
    const blip=d.blip||{};

    $('#drawer-title').textContent=t?`Editar ${t.name}`:'Cadastrar tipo';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field"><span>Nome do tipo</span><input id="t-name" value="${esc(t?.name||'')}" ${t?'disabled':''} required></label>
        <label class="field"><span>Modo</span><select id="t-mode"><option value="public" ${d.type==='public'?'selected':''}>public</option><option value="service" ${d.type==='service'?'selected':''}>service</option></select></label>

        <div class="sectiontitle"><div><b>Blip</b><span>Como a garagem aparece no mapa.</span></div></div>
        <label class="checkrow"><input id="t-show" type="checkbox" ${blip.showBlip?'checked':''}> Exibir blip no mapa</label>
        <label class="field"><span>Nome do blip</span><input id="t-blipname" value="${esc(blip.name||'Garagem')}"></label>
        <div class="grid3">
            <label class="field"><span>Sprite</span><input id="t-blipid" type="number" value="${blip.blipId??357}"></label>
            <label class="field"><span>Cor</span><input id="t-color" type="number" value="${blip.blipColor??0}"></label>
            <label class="field"><span>Escala</span><input id="t-scale" type="number" step="0.05" value="${blip.blipScale??0.5}"></label>
        </div>

        <div id="type-extra"></div>

        <div class="formactions"><button type="button" class="btn ghost cancel">Cancelar</button><button class="btn primary">Salvar tipo</button></div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    function extra(){
        const mode=$('#t-mode').value;

        if(mode==='service'){
            const vehicles=d.type==='service'?(d.vehicles||[]):[];
            $('#type-extra').innerHTML=`<div class="sectiontitle"><div><b>Veículos de serviço</b><span>Um spawn por linha. Livery opcional após vírgula.</span></div></div>
            <label class="field"><span>Lista de veículos</span><textarea id="t-vehicles" placeholder="police\npolice2, 1">${vehicles.map(v=>v.vehicle+(v.livery!=null?`, ${v.livery}`:'')).join('\n')}</textarea></label>`;
        }else{
            const lc=d.type==='public'?(d.listCars||{}):{vehicle:true,boat:true,heli:true};
            $('#type-extra').innerHTML=`<div class="sectiontitle"><div><b>Classes permitidas</b><span>Veículos que aparecem nesta garagem pública.</span></div></div>
            ${['vehicle','boat','heli'].map(k=>`<label class="checkrow"><input class="class-check" data-class="${k}" type="checkbox" ${lc[k]?'checked':''}> ${k}</label>`).join('')}`;
        }
    }

    extra();
    $('#t-mode').onchange=extra;

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const mode=$('#t-mode').value;
        const data={
            type:mode,
            blip:{
                showBlip:$('#t-show').checked,
                name:$('#t-blipname').value.trim(),
                blipId:+$('#t-blipid').value,
                blipColor:+$('#t-color').value,
                blipScale:+$('#t-scale').value
            }
        };

        if(mode==='service'){
            data.vehicles=$('#t-vehicles').value.split('\n').map(x=>x.trim()).filter(Boolean).map(x=>{
                const [vehicle,livery]=x.split(',').map(v=>v.trim());
                return livery?{vehicle,livery:+livery}:{vehicle};
            });
        }else{
            data.listCars={};
            $$('.class-check').forEach(x=>data.listCars[x.dataset.class]=x.checked);
        }

        await save(t?'updateGarageType':'createGarageType',{name:t?.name||$('#t-name').value.trim(),data});
    };
}

function shopPointRow(p={}){
    const c=p.coords||p||{};
    return `<div class="shopcoordrow">
        <input class="px" type="number" step="0.01" value="${c.x??''}" placeholder="X">
        <input class="py" type="number" step="0.01" value="${c.y??''}" placeholder="Y">
        <input class="pz" type="number" step="0.01" value="${c.z??''}" placeholder="Z">
        <label class="pointblip"><input class="pblip" type="checkbox" ${p.blip?'checked':''}> Blip</label>
        <button type="button" class="pointtp" title="Teleportar para este ponto">⌖</button>
        <button type="button" class="remove" title="Remover ponto">×</button>
    </div>`;
}

const ITEM_IMAGE_BASE = "http://127.0.0.1/images/";
const ITEM_IMAGE_FALLBACK = "data:image/svg+xml;charset=UTF-8," + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">' +
    '<rect width="64" height="64" rx="12" fill="#141b27"/>' +
    '<path d="M15 22.5 32 13l17 9.5v19L32 51l-17-9.5v-19Z" fill="none" stroke="#7c5cff" stroke-width="3" stroke-linejoin="round"/>' +
    '<path d="m15 22.5 17 9.5 17-9.5M32 32v19" fill="none" stroke="#a08cff" stroke-width="3" stroke-linejoin="round"/>' +
    '</svg>'
);

function itemImageUrl(index){
    return `${ITEM_IMAGE_BASE}${encodeURIComponent(index)}.png`;
}

function itemImage(index, className='itemthumb'){
    return `<img class="${className}" src="${itemImageUrl(index)}" alt="${esc(index)}" loading="lazy" onerror="this.onerror=null;this.src='${ITEM_IMAGE_FALLBACK}'">`;
}

function shopItemRow(index,price=0){
    const info=serverItems.find(i=>i.index===index);
    const exists=!!info;
    const label=info?.name||'Item removido da base';
    return `<div class="shopitemrow ${exists?'':'missingitem'}" data-index="${esc(index)}">
        ${itemImage(index)}
        <div class="shopiteminfo"><b>${esc(label)}</b><span>${esc(index)}${exists?'':' • removido'}</span></div>
        <input class="price" type="number" min="0" step="1" value="${Number(price)||0}" placeholder="Preço">
        <button type="button" class="remove" title="Remover item">×</button>
    </div>`;
}

function renderShopItems(){
    const box=$('#shop-items');
    if(!box)return;
    const entries=Object.entries(shopItemDraft).sort((a,b)=>{
        const an=serverItems.find(i=>i.index===a[0])?.name||a[0];
        const bn=serverItems.find(i=>i.index===b[0])?.name||b[0];
        return an.localeCompare(bn);
    });
    box.innerHTML=entries.length?entries.map(([index,price])=>shopItemRow(index,price)).join(''):
        `<div class="hint">Nenhum item selecionado. Clique em “Adicionar itens” para escolher na lista do servidor.</div>`;
    $$('#shop-items .remove').forEach(b=>b.onclick=()=>{
        const row=b.closest('.shopitemrow');
        delete shopItemDraft[row.dataset.index];
        renderShopItems();
    });
}

async function ensureServerItems(force=false){
    if(serverItems.length && !force)return true;

    const r=await nui('getItemList');
    if(!r.ok){
        toast(r.message||'Não foi possível carregar os itens do servidor.','error');
        return false;
    }

    serverItems=(r.data||[]).filter(i=>i && i.index);
    return true;
}

function renderItemPicker(){
    const q=$('#item-picker-search').value.trim().toLowerCase();
    const list=serverItems.filter(i=>!q||i.name.toLowerCase().includes(q)||i.index.toLowerCase().includes(q));
    $('#item-picker-list').innerHTML=list.length?list.map(i=>{
        const selected=pickerSelection.has(i.index);
        return `<label class="pickeritem ${selected?'selected':''}">
            <input type="checkbox" data-index="${esc(i.index)}" ${selected?'checked':''}>
            ${itemImage(i.index,'pickerthumb')}
            <div><b>${esc(i.name)}</b><span>${esc(i.index)}</span></div>
        </label>`;
    }).join(''):`<div class="pickerempty">Nenhum item encontrado.</div>`;
    $('#item-picker-count').textContent=`${pickerSelection.size} ${pickerSelection.size===1?'item selecionado':'itens selecionados'}`;
    $$('#item-picker-list input[type="checkbox"]').forEach(c=>c.onchange=()=>{
        if(pickerContext?.type==='craft-product' && c.checked){
            pickerSelection=new Set([c.dataset.index]);
            renderItemPicker();
            return;
        }
        if(c.checked)pickerSelection.add(c.dataset.index);else pickerSelection.delete(c.dataset.index);
        c.closest('.pickeritem').classList.toggle('selected',c.checked);
        $('#item-picker-count').textContent=`${pickerSelection.size} ${pickerSelection.size===1?'item selecionado':'itens selecionados'}`;
    });
}

async function openItemPicker(){
    if(!await ensureServerItems(true))return;
    restoreShopPickerHeader();
    const validItems=new Set(serverItems.map(i=>i.index));
    pickerSelection=new Set(Object.keys(shopItemDraft).filter(index=>validItems.has(index)));
    $('#item-picker-search').value='';
    $('#item-picker').classList.remove('hidden');
    renderItemPicker();
    setTimeout(()=>$('#item-picker-search').focus(),30);
}

function closeItemPicker(){ $('#item-picker').classList.add('hidden'); }

function setPickerHeader(title,subtitle,buttonText){
    const picker=$('#item-picker');
    picker.querySelector('.pickerhead h3').textContent=title;
    picker.querySelector('.pickerhead span').textContent=subtitle;
    $('#item-picker-add').textContent=buttonText;
}

async function openCraftProductPicker(recipeBox){
    if(!await ensureServerItems(true))return;
    const current=recipeBox.querySelector('.recipe-product')?.dataset.index||'';
    pickerContext={type:'craft-product',box:recipeBox};
    const validItems=new Set(serverItems.map(i=>i.index));
    pickerSelection=new Set(current && validItems.has(current)?[current]:[]);
    setPickerHeader('Selecionar item produzido','Escolha qual item esta receita irá produzir.','Usar item selecionado');
    $('#item-picker-toggle').classList.add('hidden');
    $('#item-picker-search').value='';
    $('#item-picker').classList.remove('hidden');
    renderItemPicker();
    setTimeout(()=>$('#item-picker-search').focus(),30);
}

async function openCraftMaterialsPicker(recipeBox){
    if(!await ensureServerItems(true))return;
    const selected=[...recipeBox.querySelectorAll('.craftmaterialrow')].map(r=>r.dataset.index);
    pickerContext={type:'craft-materials',box:recipeBox};
    const validItems=new Set(serverItems.map(i=>i.index));
    pickerSelection=new Set(selected.filter(index=>validItems.has(index)));
    setPickerHeader('Selecionar materiais','Marque todos os materiais necessários para fabricar este item.','Adicionar materiais');
    $('#item-picker-toggle').classList.remove('hidden');
    $('#item-picker-search').value='';
    $('#item-picker').classList.remove('hidden');
    renderItemPicker();
    setTimeout(()=>$('#item-picker-search').focus(),30);
}

function restoreShopPickerHeader(){
    pickerContext=null;
    setPickerHeader('Selecionar itens','Marque os itens que farão parte desta loja.','Adicionar selecionados');
    $('#item-picker-toggle').classList.remove('hidden');
}


function shopForm(s){
    const d=s?.data||{};
    const blip=d.blip||{};
    shopItemDraft={...(d.items||{})};

    $('#drawer-title').textContent=s?`Editar ${s.name}`:'Cadastrar loja';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field"><span>Nome da loja</span><input id="s-name" value="${esc(s?.name||'')}" required></label>

        <div class="grid2">
            <label class="field"><span>Modo</span>
                <select id="s-mode">
                    <option value="buy" ${d.mode!=='sell'?'selected':''}>Compra (buy)</option>
                    <option value="sell" ${d.mode==='sell'?'selected':''}>Venda (sell)</option>
                </select>
            </label>
            <label class="field"><span>Permissão</span><input id="s-perm" value="${esc(d.perm||'')}" placeholder="Vazio = livre"></label>
        </div>

        <label class="checkrow"><input id="s-wallet" type="checkbox" ${d.onlyWalletPayment?'checked':''}> Comprar somente com dinheiro em mãos</label>

        <div class="sectiontitle">
            <div><b>Itens e preços</b><span>Escolha diretamente entre todos os itens cadastrados no servidor.</span></div>
            <button type="button" id="pick-shop-items" class="btn primary mini">＋ Adicionar itens</button>
        </div>
        <div id="shop-items" class="shopitems"></div>
        <div class="hint">O nome amigável é exibido para facilitar a escolha, mas o JSON salva o index interno correto do item.</div>

        <div class="sectiontitle"><div><b>Configuração do blip</b><span>O blip só aparece nos pontos marcados abaixo.</span></div></div>
        <label class="checkrow"><input id="s-blip-enabled" type="checkbox" ${d.blip?'checked':''}> Esta loja possui configuração de blip</label>

        <div id="shop-blip-fields">
            <label class="field"><span>Texto do blip</span><input id="s-blip-text" value="${esc(blip.text||s?.name||'Loja')}"></label>
            <div class="grid3">
                <label class="field"><span>Sprite</span><input id="s-blip-index" type="number" value="${blip.index??52}"></label>
                <label class="field"><span>Cor</span><input id="s-blip-color" type="number" value="${blip.color??0}"></label>
                <label class="field"><span>Escala</span><input id="s-blip-scale" type="number" step="0.05" value="${blip.scale??0.5}"></label>
            </div>
        </div>

        <div class="sectiontitle">
            <div><b>Pontos da loja</b><span>Você pode cadastrar quantos markers quiser.</span></div>
            <div class="sectionbuttons">
                <button type="button" id="capture-shop-point" class="btn primary mini">⌖ Definir no jogo</button>
                <button type="button" id="add-shop-point" class="btn ghost mini">＋ Manual</button>
            </div>
        </div>

        <div class="shopcoordhead"><span>X</span><span>Y</span><span>Z</span><span>Mapa</span><span>Ir</span><span></span></div>
        <div id="shop-points">${(d.coords||[]).map(shopPointRow).join('')}</div>

        <div class="hint">Clique em “Definir no jogo”, vá até onde o marker da loja deve ficar e pressione E. Marque “Blip” apenas nos pontos que devem aparecer no mapa.</div>

        <div class="formactions"><button type="button" class="btn ghost cancel">Cancelar</button><button class="btn primary">Salvar loja</button></div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    renderShopItems();
    ensureServerItems().then(ok=>{if(ok)renderShopItems()});
    $('#pick-shop-items').onclick=openItemPicker;

    const updateBlipVisibility=()=>{
        $('#shop-blip-fields').classList.toggle('disabledfields',!$('#s-blip-enabled').checked);
        $$('#shop-blip-fields input').forEach(i=>i.disabled=!$('#s-blip-enabled').checked);
    };
    $('#s-blip-enabled').onchange=updateBlipVisibility;
    updateBlipVisibility();

    const bindShopPointActions=()=>{
        $$('#shop-points .remove').forEach(b=>b.onclick=()=>b.closest('.shopcoordrow').remove());
        $$('#shop-points .pointtp').forEach(b=>b.onclick=async()=>{
            const row=b.closest('.shopcoordrow');
            const coords={
                x:Number(row.querySelector('.px').value),
                y:Number(row.querySelector('.py').value),
                z:Number(row.querySelector('.pz').value)
            };

            if(!Number.isFinite(coords.x)||!Number.isFinite(coords.y)||!Number.isFinite(coords.z)){
                return toast('Coordenadas inválidas neste ponto.','error');
            }

            const r=await nui('teleport',{coords});
            if(!r?.ok)toast(r?.message||'Não foi possível teleportar.','error');
        });
    };
    bindShopPointActions();

    $('#add-shop-point').onclick=()=>{
        $('#shop-points').insertAdjacentHTML('beforeend',shopPointRow());
        bindShopPointActions();
    };

    $('#capture-shop-point').onclick=async()=>{
        const r=await nui('startShopPosition');
        if(!r.ok)toast(r.message||'Não foi possível iniciar o posicionamento.','error');
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const items={};
        $$('#shop-items .shopitemrow').forEach(row=>{
            const price=Number(row.querySelector('.price').value);
            if(Number.isFinite(price)&&price>=0)items[row.dataset.index]=price;
        });

        const coords=$$('#shop-points .shopcoordrow').map(r=>({
            coords:{
                x:+r.querySelector('.px').value,
                y:+r.querySelector('.py').value,
                z:+r.querySelector('.pz').value
            },
            blip:r.querySelector('.pblip').checked
        })).filter(p=>Number.isFinite(p.coords.x)&&Number.isFinite(p.coords.y)&&Number.isFinite(p.coords.z));

        const data={
            mode:$('#s-mode').value,
            perm:$('#s-perm').value.trim(),
            onlyWalletPayment:$('#s-wallet').checked,
            items,
            coords
        };

        if($('#s-blip-enabled').checked){
            data.blip={
                enabled:true,
                text:$('#s-blip-text').value.trim(),
                index:+$('#s-blip-index').value,
                color:+$('#s-blip-color').value,
                scale:+$('#s-blip-scale').value
            };
        }

        await save(s?'updateShop':'createShop',{
            originalName:s?.name,
            name:$('#s-name').value.trim(),
            data
        });
    };
}


function craftCoordRow(c={}){
    return `<div class="shopcoordrow">
        <input class="cx" type="number" step="0.01" value="${c.x??''}" placeholder="X">
        <input class="cy" type="number" step="0.01" value="${c.y??''}" placeholder="Y">
        <input class="cz" type="number" step="0.01" value="${c.z??''}" placeholder="Z">
        <button type="button" class="crafttp pointtp" title="Teleportar">⌖</button>
        <button type="button" class="remove">×</button>
    </div>`;
}
function craftMaterialRow(x={}){
    const index=x.name||x.item||'';
    const exists=itemExists(index);
    const label=exists?itemName(index):'Item removido da base';
    return `<div class="craftmaterialrow ${exists?'':'missingitem'}" data-index="${esc(index)}">
        ${itemImage(index,'craftitemthumb')}
        <div class="craftiteminfo"><b>${esc(label)}</b><span>${esc(index)}${exists?'':' • removido'}</span></div>
        <label><span>Quantidade</span><input class="materialamount" type="number" min="1" value="${Number(x.amount)||1}"></label>
        <button type="button" class="remove material-remove" title="Remover material">×</button>
    </div>`;
}

function renderRecipeProduct(box,index){
    const target=box.querySelector('.recipe-product');
    if(!target)return;
    const exists=index?itemExists(index):false;
    const label=index?(exists?itemName(index):'Item removido da base'):'Nenhum item selecionado';
    target.dataset.index=index||'';
    target.classList.toggle('missingitem',!!index&&!exists);
    target.innerHTML=index?`
        ${itemImage(index,'craftproductthumb')}
        <div class="craftiteminfo"><b>${esc(label)}</b><span>${esc(index)}${exists?'':' • removido'}</span></div>
        <button type="button" class="btn ghost mini choose-product">Trocar item</button>
    `:`
        <div class="emptyitemicon">□</div>
        <div class="craftiteminfo"><b>Nenhum item selecionado</b><span>Escolha o item que será produzido</span></div>
        <button type="button" class="btn primary mini choose-product">Selecionar item</button>
    `;
    target.querySelector('.choose-product').onclick=()=>openCraftProductPicker(box);
}

function bindCraftMaterialActions(box){
    box.querySelectorAll('.material-remove').forEach(btn=>btn.onclick=()=>btn.closest('.craftmaterialrow').remove());
}

function recipeRow(r={}){
    return `<div class="recipebox">
        <div class="recipe-product" data-index="${esc(r.spawn||'')}"></div>
        <div class="grid2">
            <label class="field"><span>Quantidade produzida</span><input class="ramount" type="number" min="1" value="${r.amount??1}"></label>
            <label class="field"><span>Tempo de produção (s)</span><input class="rtime" type="number" min="0" value="${r.time??5}"></label>
        </div>
        <div class="sectiontitle compact">
            <div><b>Materiais necessários</b><span>Selecione os itens visualmente e informe a quantidade exigida.</span></div>
            <button type="button" class="btn primary mini choose-materials">＋ Adicionar materiais</button>
        </div>
        <div class="craftmaterials">${(r.requires||[]).map(craftMaterialRow).join('')}</div>
        <button type="button" class="btn ghost mini remove-recipe">Remover receita</button>
    </div>`;
}

function farmRewardRow(x={}){
    return `<div class="spawnrow">
        <input class="fitem" list="server-items-list" value="${esc(x.item||'')}" placeholder="Item">
        <input class="fmin" type="number" min="1" value="${x.min??1}" placeholder="Min">
        <input class="fmax" type="number" min="1" value="${x.max??1}" placeholder="Max">
        <button type="button" class="remove">×</button>
    </div>`;
}
function itemExists(index){
    return serverItems.some(i=>i.index===index);
}
function itemName(index){
    return serverItems.find(i=>i.index===index)?.name||index;
}

async function craftForm(b){
    await ensureServerItems();
    const farm=craftSetups.farm||{};
    const route=(farm.Routes||[]).find(r=>r.rewardType===b?.farmRewardType);
    const rewards=(b?.farmRewardType && farm.Rewards?.[b.farmRewardType])||[];
    const firstReward=rewards[0]||{};
    const routeTypes=Object.keys(farm.RouteBlips||{});
    $('#drawer-title').textContent=b?`Editar ${b.name}`:'Cadastrar Craft + Farm';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <datalist id="server-items-list">${serverItems.map(i=>`<option value="${esc(i.index)}">${esc(i.name)}</option>`).join('')}</datalist>
        <label class="field"><span>Nome da bancada / organização</span><input id="cf-name" value="${esc(b?.name||'')}" required></label>
        <div class="grid2">
            <label class="field"><span>Permissão de craft</span><input id="cf-craftperm" value="${esc(b?.craftPermission||'')}" placeholder="perm.lidermafia"></label>
            <label class="field"><span>Permissão do armazém</span><input id="cf-storeperm" value="${esc(b?.armazemPermission||'')}" placeholder="perm.mafia"></label>
        </div>

        <div id="cf-general-view">
            <div class="sectiontitle"><div><b>Pontos da bancada</b><span>Markers onde o painel de craft abre.</span></div><button type="button" id="cf-addpos" class="btn ghost mini">＋ Usar posição atual</button></div>
            <div id="cf-positions">${(b?.coords||[]).map(craftCoordRow).join('')}</div>

            <button type="button" id="cf-open-recipes" class="recipe-manager-card">
                <div>
                    <span class="recipe-manager-icon">⌘</span>
                    <div><b>Editar receitas</b><small>Gerencie produtos, materiais, quantidades e tempo de produção.</small></div>
                </div>
                <strong>${b?.craftItems?.length||0} receitas ›</strong>
            </button>

            <div class="sectiontitle"><div><b>Farm vinculado</b><span>Ao salvar, estes dados também são gravados no JSON do m_farm.</span></div></div>
        <label class="checkrow"><input id="cf-farm-enabled" type="checkbox" ${b?.farmRewardType?'checked':''}> Criar/atualizar farm para esta bancada</label>
        <div id="cf-farm-fields">
            <div class="grid2">
                <label class="field"><span>Tipo de rota</span><select id="cf-route">${routeTypes.map(x=>`<option value="${esc(x)}" ${(b?.farmRouteType||route?.routeType)===x?'selected':''}>${esc(x)}</option>`).join('')}</select></label>
                <label class="field"><span>Identificador do reward</span><input id="cf-rewardtype" value="${esc(b?.farmRewardType||b?.name||'')}" placeholder="Mafia"></label>
            </div>
            <label class="field"><span>Permissões do farm</span><input id="cf-farmperms" value="${esc((b?.farmPermissions||route?.permissions||[]).join(', '))}" placeholder="perm.mafia"></label>
            <div class="grid2">
                <label class="field"><span>Nome exibido da rota</span><input id="cf-route-name" value="${esc(firstReward.name||'ROTA DE FARM')}"></label>
                <label class="field"><span>Imagem da rota (index)</span><input id="cf-route-image" list="server-items-list" value="${esc(firstReward.image||'')}"></label>
            </div>
            <div class="sectiontitle"><div><b>Itens recebidos no farm</b><span>Min/max por coleta.</span></div><button type="button" id="cf-addfarm" class="btn ghost mini">＋ Item</button></div>
            <div id="cf-farmitems">${(firstReward.items||[]).map(farmRewardRow).join('')}</div>
        </div>
        </div>

        <div id="cf-recipes-view" class="hidden">
            <div class="subviewhead">
                <button type="button" id="cf-back-general" class="btn ghost mini">← Voltar</button>
                <div><b>Receitas da bancada</b><span>Edite apenas as receitas sem poluir a configuração geral.</span></div>
                <button type="button" id="cf-addrecipe" class="btn primary mini">＋ Nova receita</button>
            </div>
            <div id="cf-recipes">${(b?.craftItems||[]).map(recipeRow).join('')}</div>
            <div class="subviewfooter">
                <button type="button" id="cf-back-general-bottom" class="btn ghost">← Voltar para configuração</button>
            </div>
        </div>

        <div class="formactions"><button type="button" class="btn ghost cancel">Cancelar</button><button class="btn primary">Salvar Craft + Farm</button></div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    const showCraftView=(view)=>{
        const recipes=view==='recipes';
        $('#cf-general-view').classList.toggle('hidden',recipes);
        $('#cf-recipes-view').classList.toggle('hidden',!recipes);
        $('#drawer-kicker').textContent=recipes?'RECEITAS':'CONFIGURAÇÃO';
        $('#drawer-title').textContent=recipes?`Receitas • ${$('#cf-name').value||'Nova bancada'}`:(b?`Editar ${b.name}`:'Cadastrar Craft + Farm');
        $('#drawer-body').scrollTop=0;
    };
    $('#cf-open-recipes').onclick=()=>showCraftView('recipes');
    $('#cf-back-general').onclick=()=>showCraftView('general');
    $('#cf-back-general-bottom').onclick=()=>showCraftView('general');

    const bind=()=>{
        $$('#cf-positions .remove').forEach(x=>x.onclick=()=>x.closest('.shopcoordrow').remove());
        $$('#cf-positions .crafttp').forEach(x=>x.onclick=async()=>{
            const r=x.closest('.shopcoordrow'), coords={x:+r.querySelector('.cx').value,y:+r.querySelector('.cy').value,z:+r.querySelector('.cz').value};
            await nui('teleport',{coords});
        });
        $$('#cf-recipes .recipebox').forEach(box=>{
            renderRecipeProduct(box,box.querySelector('.recipe-product')?.dataset.index||'');
            box.querySelector('.choose-materials').onclick=()=>openCraftMaterialsPicker(box);
            bindCraftMaterialActions(box);
            box.querySelector('.remove-recipe').onclick=()=>box.remove();
        });
        $$('#cf-farmitems .remove').forEach(x=>x.onclick=()=>x.closest('.spawnrow').remove());
    }; bind();
    $('#cf-addpos').onclick=async()=>{const r=await nui('getPosition'); if(r.ok){$('#cf-positions').insertAdjacentHTML('beforeend',craftCoordRow(r.coords));bind();}};
    $('#cf-addrecipe').onclick=()=>{$('#cf-recipes').insertAdjacentHTML('beforeend',recipeRow());bind();};
    $('#cf-addfarm').onclick=()=>{$('#cf-farmitems').insertAdjacentHTML('beforeend',farmRewardRow());bind();};
    const farmToggle=()=>$('#cf-farm-fields').classList.toggle('disabledfields',!$('#cf-farm-enabled').checked);
    $('#cf-farm-enabled').onchange=farmToggle; farmToggle();

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const coords=$$('#cf-positions .shopcoordrow').map(r=>({x:+r.querySelector('.cx').value,y:+r.querySelector('.cy').value,z:+r.querySelector('.cz').value})).filter(c=>Number.isFinite(c.x)&&Number.isFinite(c.y)&&Number.isFinite(c.z));
        const craftItems=$$('#cf-recipes .recipebox').map(r=>{
            const spawn=r.querySelector('.recipe-product')?.dataset.index||'';
            const requires=[...r.querySelectorAll('.craftmaterialrow')].map(row=>{
                const name=row.dataset.index;
                return {name,image:name,amount:Number(row.querySelector('.materialamount').value)||1};
            });
            return {name:itemName(spawn),image:spawn,spawn,amount:+r.querySelector('.ramount').value||1,time:+r.querySelector('.rtime').value||0,requires};
        }).filter(r=>r.spawn);
        const materialMap={};
        craftItems.forEach(r=>r.requires.forEach(q=>{if(q.name!=='money')materialMap[q.name]={name:itemName(q.name),spawn:q.name,image:q.name};}));
        const farmItems=$$('#cf-farmitems .spawnrow').map(r=>({item:r.querySelector('.fitem').value.trim(),min:+r.querySelector('.fmin').value||1,max:+r.querySelector('.fmax').value||1})).filter(x=>x.item);
        const rewardType=$('#cf-rewardtype').value.trim()||$('#cf-name').value.trim();
        const payload={
            originalName:b?.name,
            bench:{
                name:$('#cf-name').value.trim(),
                craftPermission:$('#cf-craftperm').value.trim(),
                armazemPermission:$('#cf-storeperm').value.trim(),
                coords,craftItems,armazemItems:Object.values(materialMap),
                farmRewardType:b?.farmRewardType||''
            },
            farm:{
                enabled:$('#cf-farm-enabled').checked,
                rewardType,
                routeType:$('#cf-route').value,
                permissions:$('#cf-farmperms').value.split(',').map(x=>x.trim()).filter(Boolean),
                rewards:[{name:$('#cf-route-name').value.trim()||'ROTA DE FARM',image:$('#cf-route-image').value.trim()||farmItems[0]?.item||'',items:farmItems}]
            }
        };
        await save('saveCraftSetup',payload);
    };
}



function clothingForm(s){
    $('#drawer-title').textContent=s?`Editar local #${s.id}`:'Novo local da loja de roupa';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        ${s?`<div class="hint">Editando o ponto <b>#${esc(s.id)}</b>. Altere a localização abaixo ou use sua posição atual.</div>`:''}
        ${coordsBlock('cloth',s?.coords)}
        <div class="hint">Não existe permissão ou configuração adicional: este módulo controla somente a localização.</div>
        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            ${s?`<button type="button" id="cloth-tp" class="btn ghost">⌖ Teleportar para este ponto</button>`:''}
            <button class="btn primary">${s?'Salvar nova posição':'Cadastrar local'}</button>
        </div>
    </form>`;

    bindPosition('cloth');
    $('.cancel').onclick=closeDrawer;

    if(s){
        $('#cloth-tp').onclick=async()=>{
            const r=await nui('teleport',{coords:s.coords});
            if(!r?.ok)toast(r?.message||'Não foi possível teleportar.','error');
        };
    }

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const coords={
            x:+$('#cloth-x').value,
            y:+$('#cloth-y').value,
            z:+$('#cloth-z').value
        };
        if(!Number.isFinite(coords.x)||!Number.isFinite(coords.y)||!Number.isFinite(coords.z)){
            return toast('Coordenadas inválidas.','error');
        }
        await save(s?'updateClothingShop':'createClothingShop',s?{id:s.id,coords}:{coords});
    };
}



function barbershopForm(s){
    $('#drawer-title').textContent=s?`Editar barbearia #${s.id}`:'Novo local da barbearia';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        ${s?`<div class="hint">Editando o ponto <b>#${esc(s.id)}</b>. Altere a localização ou use sua posição atual.</div>`:''}
        ${coordsBlock('barber',s?.coords)}
        <div class="hint">Este módulo controla somente a localização da barbearia.</div>
        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            ${s?`<button type="button" id="barber-tp" class="btn ghost">⌖ Teleportar para este ponto</button>`:''}
            <button class="btn primary">${s?'Salvar nova posição':'Cadastrar local'}</button>
        </div>
    </form>`;

    bindPosition('barber');
    $('.cancel').onclick=closeDrawer;

    if(s){
        $('#barber-tp').onclick=async()=>{
            const r=await nui('teleport',{coords:s.coords});
            if(!r?.ok)toast(r?.message||'Não foi possível teleportar.','error');
        };
    }

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const coords={
            x:+$('#barber-x').value,
            y:+$('#barber-y').value,
            z:+$('#barber-z').value
        };
        if(!Number.isFinite(coords.x)||!Number.isFinite(coords.y)||!Number.isFinite(coords.z)){
            return toast('Coordenadas inválidas.','error');
        }
        await save(s?'updateBarbershop':'createBarbershop',s?{id:s.id,coords}:{coords});
    };
}



function tattooForm(s){
    $('#drawer-title').textContent=s?`Editar Tattoo #${s.id}`:'Novo local do Estúdio Tattoo';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        ${s?`<div class="hint">Editando o ponto <b>#${esc(s.id)}</b>. Altere a localização ou use sua posição atual.</div>`:''}

        ${coordsBlock('tattoo',s?.coords)}

        <div class="hint">
            Este módulo controla somente a localização do Estúdio Tattoo.
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>

            ${s?`
                <button type="button" id="tattoo-tp" class="btn ghost">
                    ⌖ Teleportar para este ponto
                </button>
            `:''}

            <button class="btn primary">
                ${s?'Salvar nova posição':'Cadastrar local'}
            </button>
        </div>
    </form>`;

    bindPosition('tattoo');
    $('.cancel').onclick=closeDrawer;

    if(s){
        $('#tattoo-tp').onclick=async()=>{
            const r=await nui('teleport',{coords:s.coords});

            if(!r?.ok){
                toast(r?.message||'Não foi possível teleportar.','error');
            }
        };
    }

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const coords={
            x:+$('#tattoo-x').value,
            y:+$('#tattoo-y').value,
            z:+$('#tattoo-z').value
        };

        if(
            !Number.isFinite(coords.x) ||
            !Number.isFinite(coords.y) ||
            !Number.isFinite(coords.z)
        ){
            return toast('Coordenadas inválidas.','error');
        }

        await save(
            s?'updateTattooShop':'createTattooShop',
            s?{id:s.id,coords}:{coords}
        );
    };
}



function cloakUniformRow(u={}){
    const masc=u.masculino&&Object.keys(u.masculino).length>0;
    const fem=u.feminino&&Object.keys(u.feminino).length>0;
    const payload=encodeURIComponent(JSON.stringify({
        masculino:u.masculino||{},
        feminino:u.feminino||{}
    }));

    return `<div class="cloakuniform" data-outfits="${payload}">
        <div class="cloakuniformtop">
            <label class="field cloakuniformname">
                <span>Nome do fardamento</span>
                <input class="cu-name" value="${esc(u.name||'Novo Fardamento')}" required>
            </label>
            <button type="button" class="btn ghost mini cu-capture">⌖ Capturar roupa atual</button>
            <button type="button" class="rowbtn del cu-remove" title="Excluir fardamento">×</button>
        </div>
        <div class="cloakstatus">
            <span class="${masc?'ready':''}">Masculino: ${masc?'capturado':'não definido'}</span>
            <span class="${fem?'ready':''}">Feminino: ${fem?'capturado':'não definido'}</span>
        </div>
        <small class="muted">Ao capturar novamente, apenas o gênero atual do personagem é atualizado.</small>
    </div>`;
}

function getUniformRowData(row){
    let outfits={masculino:{},feminino:{}};
    try{outfits=JSON.parse(decodeURIComponent(row.dataset.outfits||''))}catch{}
    return {
        name:row.querySelector('.cu-name').value.trim(),
        masculino:outfits.masculino||{},
        feminino:outfits.feminino||{}
    };
}

function updateUniformRow(row,data){
    row.dataset.outfits=encodeURIComponent(JSON.stringify({
        masculino:data.masculino||{},
        feminino:data.feminino||{}
    }));
    const status=row.querySelector('.cloakstatus');
    const masc=data.masculino&&Object.keys(data.masculino).length>0;
    const fem=data.feminino&&Object.keys(data.feminino).length>0;
    status.innerHTML=`
        <span class="${masc?'ready':''}">Masculino: ${masc?'capturado':'não definido'}</span>
        <span class="${fem?'ready':''}">Feminino: ${fem?'capturado':'não definido'}</span>`;
}

function bindCloakUniformRows(){
    $$('#cloak-uniforms .cloakuniform').forEach(row=>{
        row.querySelector('.cu-remove').onclick=()=>row.remove();
        row.querySelector('.cu-capture').onclick=async()=>{
            const r=await nui('getCurrentOutfit');
            if(!r?.ok)return toast(r?.message||'Não foi possível capturar a roupa atual.','error');

            const data=getUniformRowData(row);
            data[r.gender]=r.outfit||{};
            updateUniformRow(row,data);
            toast(`Roupa ${r.gender==='masculino'?'masculina':'feminina'} capturada.`);
        };
    });
}

function cloakroomForm(room){
    $('#drawer-title').textContent=room?`Editar ${room.name}`:'Novo Blip Fardamento';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field">
                <span>Nome / Identificador</span>
                <input id="cl-name" value="${esc(room?.name||'')}" placeholder="POLICIA" required>
            </label>
            <label class="field">
                <span>Permissão</span>
                <input id="cl-perm" value="${esc(room?.permission||'')}" placeholder="perm.policia">
            </label>
        </div>

        ${coordsBlock('cl',room?.coords)}

        <div class="sectiontitle">
            <div>
                <b>Fardamentos</b>
                <span>Capture a roupa completa que seu personagem está usando.</span>
            </div>
            <button type="button" id="cl-add-uniform" class="btn primary mini">＋ Adicionar fardamento atual</button>
        </div>

        <div id="cloak-uniforms">${(room?.uniforms||[]).map(cloakUniformRow).join('')}</div>

        <div class="hint">
            Componentes, texturas, paleta e props são capturados automaticamente. 
            Para configurar os dois gêneros do mesmo fardamento, capture uma vez com personagem masculino e outra com feminino.
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            ${room?`<button type="button" id="cl-tp" class="btn ghost">⌖ Teleportar</button>`:''}
            <button class="btn primary">Salvar Blip Fardamento</button>
        </div>
    </form>`;

    bindPosition('cl');
    $('.cancel').onclick=closeDrawer;
    bindCloakUniformRows();

    if(room){
        $('#cl-tp').onclick=async()=>{
            const r=await nui('teleport',{coords:room.coords});
            if(!r?.ok)toast(r?.message||'Não foi possível teleportar.','error');
        };
    }

    $('#cl-add-uniform').onclick=async()=>{
        const r=await nui('getCurrentOutfit');
        if(!r?.ok)return toast(r?.message||'Não foi possível capturar a roupa atual.','error');

        const u={name:'Novo Fardamento',masculino:{},feminino:{}};
        u[r.gender]=r.outfit||{};
        $('#cloak-uniforms').insertAdjacentHTML('beforeend',cloakUniformRow(u));
        bindCloakUniformRows();

        const row=$('#cloak-uniforms').lastElementChild;
        row.querySelector('.cu-name').focus();
        row.querySelector('.cu-name').select();
        toast('Roupa atual capturada. Agora dê um nome ao fardamento.');
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const name=$('#cl-name').value.trim();
        const permission=$('#cl-perm').value.trim();
        const coords={
            x:+$('#cl-x').value,
            y:+$('#cl-y').value,
            z:+$('#cl-z').value
        };

        if(!name)return toast('Informe o nome do Blip Fardamento.','error');
        if(!Number.isFinite(coords.x)||!Number.isFinite(coords.y)||!Number.isFinite(coords.z))
            return toast('Coordenadas inválidas.','error');

        const uniforms=$$('#cloak-uniforms .cloakuniform')
            .map(getUniformRowData)
            .filter(u=>u.name);

        await save('saveCloakroom',{
            originalName:room?.name||'',
            room:{name,permission,coords,uniforms}
        });
    };
}




function groupPermissionRow(value='',auto=false){
    return `<div class="group-permission-row" data-auto="${auto?'1':'0'}">
        <input class="gp-value" value="${esc(value)}" placeholder="perm.exemplo">
        <button type="button" class="rowbtn del gp-remove" title="Remover">×</button>
    </div>`;
}

function bindGroupPermissionRows(){
    $$('#group-permissions .group-permission-row').forEach(row=>{
        row.querySelector('.gp-remove').onclick=()=>row.remove();
        row.querySelector('.gp-value').addEventListener('input',()=>{
            row.dataset.auto='0';
        });
    });
}


const GROUP_TYPE_OPTIONS=['staff','org','emp','dm','vip'];
const ORG_TYPE_OPTIONS=['Armas','Municao','Drogas','Lavagem','Desmanche'];

function groupSelectOption(value,current,label=null){
    const selected=String(value)===String(current)?'selected':'';
    return `<option value="${esc(value)}" ${selected}>${esc(label||value)}</option>`;
}


function getFacNames(){
    const set=new Set();

    managedGroups.forEach(g=>{
        if(String(g.config?.gtype||'')==='org'){
            const org=String(g.config?.orgName||'').trim();
            if(org)set.add(org);
        }
    });

    return [...set].sort((a,b)=>a.localeCompare(b,undefined,{sensitivity:'base'}));
}










function dealershipCategoryOptions(selected){
    const cats=dealershipData.categories||[];
    return cats.map(c=>`<option value="${esc(c.id)}" ${String(selected)===String(c.id)?'selected':''}>${esc(c.label||c.id)}</option>`).join('');
}


function refreshServerBulkControls(){
    const btn=$('#server-vehicle-bulk-delete');
    if(btn){
        btn.textContent=`Apagar selecionados (${serverVehicleBulkSelection.size})`;
        btn.disabled=serverVehicleBulkSelection.size===0;
    }

    const all=$('#server-bulk-check-visible');
    if(all){
        const visible=serverVehicleVisibleSpawns||[];
        const selected=visible.filter(spawn=>serverVehicleBulkSelection.has(spawn)).length;
        all.checked=visible.length>0&&selected===visible.length;
        all.indeterminate=selected>0&&selected<visible.length;
    }
}

function openServerVehicleBulkConfirm(){
    const total=serverVehicleBulkSelection.size;
    if(!total)return toast('Selecione pelo menos um veículo.','error');

    const modal=$('#confirm');
    if(!modal)return toast('Modal de confirmação não encontrado.','error');

    $('#confirm-title').textContent=`Excluir ${total} veículo${total===1?'':'s'} do servidor?`;
    $('#confirm-text').innerHTML=`Os <b>${total} veículos selecionados</b> serão removidos de uma só vez do <b>shared-side/listcars.json</b>.<br><br>Essa ação atualiza o catálogo do m_garage em tempo real.`;

    modal.classList.remove('hidden');

    const ok=$('#confirm-ok');
    const cancel=$('#confirm-cancel');
    const previousOk=ok.onclick;
    const previousCancel=cancel.onclick;

    const cleanup=()=>{
        modal.classList.add('hidden');
        ok.onclick=previousOk;
        cancel.onclick=previousCancel;
        ok.disabled=false;
        cancel.disabled=false;
        ok.textContent='Excluir';
    };

    cancel.onclick=cleanup;

    ok.onclick=async()=>{
        const vehicles=[...serverVehicleBulkSelection];
        ok.disabled=true;
        cancel.disabled=true;
        ok.textContent='Excluindo...';

        const r=await nui('deleteServerVehiclesBatch',{vehicles});
        if(!r?.ok){
            ok.disabled=false;
            cancel.disabled=false;
            ok.textContent='Excluir';
            return toast(r?.message||'Não foi possível excluir os veículos.','error');
        }

        const removed=Array.isArray(r.data?.removed)?r.data.removed:vehicles;
        removed.forEach(spawn=>{
            delete serverVehicleCatalog[spawn];
            if(dealershipData?.runtimeVehicles?.[spawn])delete dealershipData.runtimeVehicles[spawn];
            serverVehicleBulkSelection.delete(spawn);
        });

        serverVehicleBulkMode=false;
        cleanup();
        toast(r.message||`${removed.length} veículos removidos.`);
        updateModuleFilters(false);
        render();
        syncGroupTopActions();
    };
}

function dealershipVehicleForm(vehicle){
    const spawn=vehicle?.spawn||'';
    const currentState=spawn?(dealershipData.vehicles?.[spawn]||{}):{};
    const currentMeta=spawn?(serverVehicleCatalog?.[spawn]||dealershipData.runtimeVehicles?.[spawn]||{}):{};
    const imageBase=String(dealershipData.settings?.imagesDir||'http://127.0.0.1/vrp_images/');

    $('#drawer-title').textContent=spawn?`Estoque: ${currentMeta.name||spawn}`:'Cadastrar veículo concessionária';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="hint">
            Aqui você cadastra <b>somente o spawn e o estoque</b>. Nome, valor, porta-malas e tipo são puxados automaticamente do catálogo de veículos do servidor.
        </div>

        <div class="grid2">
            <label class="field">
                <span>Spawn do veículo</span>
                <input id="deal-stock-spawn" value="${esc(spawn)}" placeholder="sultanrs" ${spawn?'disabled':''} required>
            </label>
            <label class="field">
                <span>Quantidade em estoque</span>
                <input id="deal-stock-qty" type="number" min="0" value="${currentState.stock??0}" required>
            </label>
        </div>

        <div id="deal-stock-preview" class="dealership-preview ${currentMeta.name?'':'hidden'}">
            <div class="dealership-preview-image">
                <img id="deal-stock-image" src="${spawn?esc(imageBase+spawn+'.png'):''}" onerror="this.style.display='none'" alt="">
            </div>
            <div>
                <b id="deal-stock-name">${esc(currentMeta.name||spawn)}</b>
                <span id="deal-stock-info">${currentMeta.price!=null?`R$ ${Number(currentMeta.price).toLocaleString('pt-BR')} · ${Number(currentMeta.trunk)||0} kg · ${esc(currentMeta.type||'outros')}`:''}</span>
            </div>
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">${spawn?'Salvar estoque':'Cadastrar na concessionária'}</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    const updatePreview=()=>{
        const sp=$('#deal-stock-spawn').value.trim().toLowerCase();
        const meta=serverVehicleCatalog?.[sp];
        const box=$('#deal-stock-preview');
        if(!meta){
            box.classList.add('hidden');
            return;
        }
        box.classList.remove('hidden');
        $('#deal-stock-name').textContent=meta.name||sp;
        $('#deal-stock-info').textContent=`R$ ${Number(meta.price||0).toLocaleString('pt-BR')} · ${Number(meta.trunk)||0} kg · ${meta.type||'outros'}`;
        const img=$('#deal-stock-image');
        img.style.display='';
        img.src=imageBase+sp+'.png';
    };

    if(!spawn)$('#deal-stock-spawn').oninput=updatePreview;

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const sp=(spawn||$('#deal-stock-spawn').value).trim().toLowerCase();
        const stock=Number($('#deal-stock-qty').value);
        if(!sp)return toast('Informe o spawn do veículo.','error');
        if(!serverVehicleCatalog?.[sp])return toast('Este spawn não existe no catálogo do servidor. Cadastre-o primeiro em "Cadastrar veículo servidor".','error');
        if(!Number.isFinite(stock)||stock<0)return toast('Quantidade de estoque inválida.','error');

        const r=await nui('saveDealershipVehicle',{spawn:sp,stock});
        if(!r?.ok)return toast(r?.message||'Não foi possível salvar o estoque.','error');
        await loadAll(true);
        toast(r.message||'Estoque atualizado.');
        closeDrawer();
    };
}

function serverVehicleForm(existing){
    const v=existing||{};
    const spawn=v.spawn||v.model||'';
    const knownTypes=[...new Set(Object.values(serverVehicleCatalog||{}).map(x=>String(x.type||'')).filter(Boolean))].sort();

    $('#drawer-title').textContent=existing?`Editar veículo servidor: ${v.name||spawn}`:'Cadastrar veículo servidor';
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="hint">
            Este cadastro altera diretamente o <b>shared-side/listcars.json</b> do <b>m_garage</b>. A estrutura <b>listCars</b> continua sendo atualizada em tempo real para os outros scripts.
        </div>

        <div class="grid2">
            <label class="field"><span>Spawn / Model</span><input id="sv-spawn" value="${esc(spawn)}" placeholder="sultanrs" required></label>
            <label class="field"><span>Nome exibido</span><input id="sv-name" value="${esc(v.name||'')}" placeholder="Sultan RS" required></label>
        </div>

        <div class="grid3">
            <label class="field"><span>Valor</span><input id="sv-price" type="number" min="0" value="${v.price??0}" required></label>
            <label class="field"><span>Peso / Porta-malas</span><input id="sv-trunk" type="number" min="0" value="${v.trunk??0}" required></label>
            <label class="field">
                <span>Tipo / Categoria</span>
                <input id="sv-type" list="server-vehicle-types" value="${esc(v.type||'')}" placeholder="sedans" required>
                <datalist id="server-vehicle-types">${knownTypes.map(t=>`<option value="${esc(t)}">`).join('')}</datalist>
            </label>
        </div>

        <label class="checkrow">
            <input id="sv-banned" type="checkbox" ${v.banned?'checked':''}>
            Veículo banido/bloqueado
        </label>

        <div class="hint">
            Campos salvos: <b>model, price, banned, name, trunk e type</b> — os mesmos campos do antigo shared.listcars.lua.
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">${existing?'Salvar veículo servidor':'Cadastrar veículo servidor'}</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    if(!existing){
        $('#sv-spawn').oninput=()=>{
            const sp=$('#sv-spawn').value.trim().toLowerCase();
            const found=serverVehicleCatalog?.[sp];
            if(!found)return;

            $('#sv-name').value=found.name||sp;
            $('#sv-price').value=Number(found.price)||0;
            $('#sv-trunk').value=Number(found.trunk)||0;
            $('#sv-type').value=found.type||'outros';
            $('#sv-banned').checked=found.banned===true;
        };
    }

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const newSpawn=$('#sv-spawn').value.trim().toLowerCase();
        if(!newSpawn)return toast('Informe o spawn do veículo.','error');

        const payload={
            model:newSpawn,
            name:$('#sv-name').value.trim()||newSpawn,
            price:Number($('#sv-price').value),
            trunk:Number($('#sv-trunk').value),
            type:$('#sv-type').value.trim()||'outros',
            banned:$('#sv-banned').checked
        };

        const originalSpawn=spawn.toLowerCase()||(serverVehicleCatalog?.[newSpawn]?newSpawn:'');
        const r=await nui('saveServerVehicle',{
            originalSpawn,
            spawn:newSpawn,
            data:payload
        });

        if(!r?.ok)return toast(r?.message||'Não foi possível salvar o veículo do servidor.','error');

        await loadAll(true);
        toast(r.message||'Veículo do servidor salvo.');
        closeDrawer();
    };
}


function dealershipVipRow(v={}){
    return `<div class="deal-vip-row">
        <input class="deal-vip-permission" value="${esc(v.permission||'')}" placeholder="perm.vip">
        <input class="deal-vip-discount" type="number" min="0" max="100" step="0.01" value="${v.discount??0}" placeholder="Desconto %">
        <input class="deal-vip-maxcars" type="number" min="0" value="${v.maxCars??0}" placeholder="+ Vagas">
        <button type="button" class="remove">×</button>
    </div>`;
}

function bindDealershipVipRows(){
    $$('#deal-vips .remove').forEach(b=>b.onclick=()=>b.closest('.deal-vip-row').remove());
}

function dealershipSettingsForm(){
    const data=JSON.parse(JSON.stringify(dealershipData||{settings:{},testDrive:{},categories:[],vips:[],vehicles:{}}));
    const s=data.settings||{};
    const td=data.testDrive||{};

    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Configurações da Concessionária';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="sectiontitle"><div><b>Configurações gerais</b><span>Venda, vagas, imagens e cooldowns.</span></div></div>
        <div class="grid3">
            <label class="field"><span>% descontado na revenda</span><input id="deal-sell-percent" type="number" min="0" max="100" step="0.01" value="${s.sellVehicle??99}"></label>
            <label class="field"><span>Máximo padrão de carros</span><input id="deal-max-cars" type="number" min="0" value="${s.maxCars??5}"></label>
            <label class="field"><span>Comando administrativo</span><input id="deal-command" value="${esc(s.commandConce||'conce')}"></label>
        </div>

        <label class="field"><span>Diretório das imagens</span><input id="deal-images" value="${esc(s.imagesDir||'http://127.0.0.1/vrp_images/')}"></label>

        <div class="grid3">
            <label class="field"><span>Cooldown compra (s)</span><input id="deal-buy-cool" type="number" min="0" value="${s.purchaseCooldown??5}"></label>
            <label class="field"><span>Cooldown venda (s)</span><input id="deal-sell-cool" type="number" min="0" value="${s.sellCooldown??10}"></label>
            <label class="field"><span>Tempo Test Drive (s)</span><input id="deal-test-time" type="number" min="1" value="${td.cooldownTestDriver??60}"></label>
        </div>

        <label class="field"><span>Distância máxima Test Drive</span><input id="deal-test-distance" type="number" min="1" step="0.1" value="${td.maxDistanceTestDriver??1500}"></label>
        <label class="field"><span>Webhook de compras</span><input id="deal-webhook" value="${esc(s.purchaseLogWebhook||'')}" placeholder="Opcional"></label>

        <div class="sectiontitle">
            <div><b>Descontos e vagas VIP</b><span>Cada permissão pode oferecer desconto e vagas extras.</span></div>
            <button type="button" id="deal-add-vip" class="btn ghost mini">＋ Adicionar VIP</button>
        </div>
        <div class="deal-vip-head"><span>Permissão</span><span>Desconto (%)</span><span>Vagas extras</span><span></span></div>
        <div id="deal-vips">${(data.vips||[]).map(dealershipVipRow).join('')}</div>

        <div class="sectiontitle">
            <div><b>Configuração avançada</b><span>Edite categorias, locais da concessionária, spawn do Test Drive e ranking padrão.</span></div>
        </div>
        <div class="hint">O JSON abaixo contém todas as opções restantes da concessionária. Os veículos são administrados individualmente pela lista principal.</div>
        <label class="field"><span>JSON de configurações</span><textarea id="deal-settings-json" class="job-json-editor" spellcheck="false">${esc(JSON.stringify({
            settings:data.settings||{},
            testDrive:data.testDrive||{},
            categories:data.categories||[],
            vips:data.vips||[]
        },null,2))}</textarea></label>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Salvar configurações</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    bindDealershipVipRows();

    $('#deal-add-vip').onclick=()=>{
        $('#deal-vips').insertAdjacentHTML('beforeend',dealershipVipRow());
        bindDealershipVipRows();
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        let advanced;
        try{advanced=JSON.parse($('#deal-settings-json').value||'{}')}
        catch{return toast('O JSON avançado possui erro de sintaxe.','error')}

        const vips=$$('#deal-vips .deal-vip-row').map(row=>({
            permission:row.querySelector('.deal-vip-permission').value.trim(),
            discount:Number(row.querySelector('.deal-vip-discount').value)||0,
            maxCars:Number(row.querySelector('.deal-vip-maxcars').value)||0
        })).filter(x=>x.permission);

        advanced.settings=advanced.settings||{};
        Object.assign(advanced.settings,{
            sellVehicle:Number($('#deal-sell-percent').value)||0,
            maxCars:Number($('#deal-max-cars').value)||0,
            commandConce:$('#deal-command').value.trim()||'conce',
            imagesDir:$('#deal-images').value.trim()||'http://127.0.0.1/vrp_images/',
            purchaseCooldown:Number($('#deal-buy-cool').value)||0,
            sellCooldown:Number($('#deal-sell-cool').value)||0,
            purchaseLogWebhook:$('#deal-webhook').value.trim()
        });
        advanced.testDrive=advanced.testDrive||{};
        advanced.testDrive.cooldownTestDriver=Number($('#deal-test-time').value)||60;
        advanced.testDrive.maxDistanceTestDriver=Number($('#deal-test-distance').value)||1500;
        advanced.vips=vips;

        const r=await nui('saveDealershipSettings',{
            settings:advanced.settings,
            testDrive:advanced.testDrive,
            categories:Array.isArray(advanced.categories)?advanced.categories:(data.categories||[]),
            vips
        });
        if(!r?.ok)return toast(r?.message||'Não foi possível salvar a concessionária.','error');

        await loadAll(true);
        toast(r.message||'Concessionária atualizada.');
        dealershipSettingsForm();
    };
}


function mansionPositionBlock(prefix,target,title,description,c,heading=false){
    return `<div class="mansion-position-card">
        <div class="sectiontitle">
            <div><b>${esc(title)}</b><span>${esc(description)}</span></div>
            <button type="button" class="btn primary mini mansion-position-capture" data-target="${esc(target)}" data-heading="${heading?'1':'0'}" data-label="${esc(title)}">⌖ Definir no jogo</button>
        </div>
        <div class="${heading?'grid4':'grid3'}">
            <label class="field"><span>X</span><input id="${prefix}-x" type="number" step="0.01" value="${c?.x??''}" required></label>
            <label class="field"><span>Y</span><input id="${prefix}-y" type="number" step="0.01" value="${c?.y??''}" required></label>
            <label class="field"><span>Z</span><input id="${prefix}-z" type="number" step="0.01" value="${c?.z??''}" required></label>
            ${heading?`<label class="field"><span>Heading</span><input id="${prefix}-w" type="number" step="0.01" value="${c?.w??0}" required></label>`:''}
        </div>
    </div>`;
}

function mansionPermissionFromGroup(group){
    const slug=groupPermissionSlug(group);
    return slug?`perm.${slug}`:'';
}

function mansionVoucherOptions(selected){
    const options=[
        ['valemansao500k','Vale Mansão 500K'],
        ['valemansao1m','Vale Mansão 1M'],
        ['valemansao8m','Vale Mansão 8M'],
        ['valemansao10m','Vale Mansão 10M'],
        ['valemansao100m','Vale Mansão 100M']
    ];
    return options.map(([v,l])=>`<option value="${v}" ${v===selected?'selected':''}>${l} (${v})</option>`).join('');
}

function updateMansionDoorStatus(){
    const el=$('#mansion-door-status');
    if(!el)return;
    const count=mansionDoorDraft.length;
    el.innerHTML=count
        ?`<b>${count} tranca(s) configurada(s)</b><span>Ao salvar, todas receberão automaticamente a permissão da mansão.</span>`
        :'<b>Nenhuma tranca configurada</b><span>Você pode cadastrar uma ou várias portas pelo doorsv2.</span>';
    const clear=$('#mansion-clear-doors');
    if(clear)clear.disabled=count===0;
}

function applyMansionCapturedPosition(target,c){
    if(!c)return;
    if(target==='garageSpawn'){
        const box=$('#mansion-spawns');
        if(!box)return;
        box.insertAdjacentHTML('beforeend',spawnRow({x:c.x,y:c.y,z:c.z,w:c.w??0}));
        enhanceAllPanelCoordinates(box);
        bindMansionSpawnRows();
        toast('Posição do veículo adicionada.');
        return;
    }

    const prefix={purchase:'ms-buy',chest:'ms-chest',garage:'ms-garage'}[target];
    if(!prefix)return;
    const x=$(`#${prefix}-x`),y=$(`#${prefix}-y`),z=$(`#${prefix}-z`);
    if(x)x.value=c.x;
    if(y)y.value=c.y;
    if(z)z.value=c.z;
    const combined=x?.closest('.grid3,.grid4')?.querySelector('.coordinate-combined-input');
    if(combined){
        combined.value=panelCoordinateText(c.x,c.y,c.z);
        combined.dispatchEvent(new Event('input'));
    }
    toast('Posição definida no jogo.');
}

function bindMansionSpawnRows(){
    $$('#mansion-spawns .remove').forEach(btn=>btn.onclick=()=>btn.closest('.spawnrow').remove());
}

function mansionForm(mansion){
    const m=mansion||{};
    mansionDoorDraft=JSON.parse(JSON.stringify(m.doors||[]));
    const permission=m.permission||mansionPermissionFromGroup(m.group||'');
    const typeOptions=garageTypes.map(t=>`<option value="${esc(t.name)}" ${m.garage?.type===t.name?'selected':''}>${esc(t.name)}</option>`).join('');

    $('#drawer-title').textContent=mansion?`Editar ${m.name}`:'Cadastrar nova mansão';
    $('#drawer-body').innerHTML=`<form id="form" class="form mansion-form">
        <div class="mansion-section-intro">
            <b>Identificação da mansão</b>
            <span>O sistema criará automaticamente cargo, permissão, acessos e o blip da mansão.</span>
        </div>

        <label class="field"><span>Nome da Mansão</span><input id="ms-name" value="${esc(m.name||'')}" placeholder="Ex.: Mansão Vinewood" required></label>

        <div class="grid2">
            <label class="field"><span>Cargo da mansão</span><input id="ms-group" value="${esc(m.group||'')}" placeholder="Ex.: MansaoVinewood" required></label>
            <label class="field"><span>Permissão criada automaticamente</span><input id="ms-permission" value="${esc(permission)}" readonly></label>
        </div>
        <div class="hint">O cargo será criado no mesmo sistema de <b>Gerenciar Cargos</b>. A permissão será aplicada automaticamente ao baú, garagem e trancas.</div>

        <div class="grid4 mansion-main-values">
            <label class="field"><span>Valor exibido da mansão</span><input id="ms-price" type="number" min="0" step="1" value="${m.price??''}" placeholder="Ex.: 10000000" required></label>
            <label class="field"><span>Valor do IPTU</span><input id="ms-iptu" type="number" min="1" step="1" value="${m.iptuValue??''}" placeholder="Ex.: 250000" required></label>
            <label class="field"><span>Vale necessário para comprar</span><select id="ms-voucher" required>${mansionVoucherOptions(m.voucher||'valemansao1m')}</select></label>
            <label class="field"><span>Máximo de moradores</span><input id="ms-max" type="number" min="1" step="1" value="${m.maxResidents??1}" required></label>
        </div>
        <div class="hint">O limite de moradores <b>inclui o proprietário</b>. O IPTU vence a cada <b>20 dias</b>; enquanto estiver vencido, os acessos da mansão ficam bloqueados até o pagamento.</div>

        ${mansionPositionBlock('ms-buy','purchase','Local de compra','Marker onde a mansão poderá ser adquirida.',m.purchaseCoords)}

        <div class="mansion-resource-box">
            <label class="checkrow mansion-resource-toggle"><input id="ms-chest-enabled" type="checkbox" ${m.chest?.enabled!==false?'checked':''}> Criar baú da mansão</label>
            <div id="ms-chest-fields">
                <div class="grid2">
                    <label class="field"><span>Peso do baú</span><input id="ms-chest-weight" type="number" min="1" value="${m.chest?.weight??1000}"></label>
                    <label class="field"><span>Permissão do baú</span><input id="ms-chest-perm-preview" value="${esc(permission)}" readonly></label>
                </div>
                ${mansionPositionBlock('ms-chest','chest','Baú da mansão','Fique exatamente onde o baú deverá ser acessado.',m.chest?.coords)}
            </div>
        </div>

        <div class="mansion-resource-box">
            <label class="checkrow mansion-resource-toggle"><input id="ms-garage-enabled" type="checkbox" ${m.garage?.enabled!==false?'checked':''}> Criar garagem da mansão</label>
            <div id="ms-garage-fields">
                <div class="grid2">
                    <label class="field"><span>Tipo da garagem</span><select id="ms-garage-type"><option value="">Selecione...</option>${typeOptions}</select></label>
                    <label class="field"><span>Distância do marker</span><input id="ms-garage-distance" type="number" min="0.1" step="0.1" value="${m.garage?.blipDistance??5}"></label>
                </div>
                <label class="field"><span>Permissão da garagem</span><input id="ms-garage-perm-preview" value="${esc(permission)}" readonly></label>
                ${mansionPositionBlock('ms-garage','garage','Marker da garagem','Fique onde o jogador deverá acessar a garagem.',m.garage?.coords)}

                <div class="sectiontitle">
                    <div><b>Posições dos veículos</b><span>Defina uma ou mais vagas com posição e direção.</span></div>
                    <button type="button" id="mansion-capture-spawn" class="btn primary mini">⌖ Definir posição do veículo</button>
                </div>
                <div id="mansion-spawns">${(m.garage?.spawnCoords||[]).map(spawnRow).join('')}</div>
            </div>
        </div>

        <div class="mansion-resource-box mansion-door-box">
            <div class="sectiontitle mansion-door-title">
                <div><b>Trancas da mansão</b><span>Integração direta com o doorsv2.</span></div>
                <div class="sectionbuttons">
                    <button type="button" id="mansion-capture-doors" class="btn primary mini">▣ Definir trancas</button>
                    <button type="button" id="mansion-clear-doors" class="btn ghost mini">× Limpar</button>
                </div>
            </div>
            <div id="mansion-door-status" class="mansion-door-status"></div>
            <div class="hint">Ao clicar em <b>Definir trancas</b>, o painel será ocultado. Aponte para cada porta e use <b>Mouse 1</b> para adicionar. Pressione <b>F</b> para finalizar e voltar ao cadastro. Todas as portas usarão automaticamente a permissão desta mansão.</div>
        </div>

        ${m.ownerId?`<div class="mansion-owner-card"><b>Mansão ocupada</b><span>Proprietário atual: ${esc((m.residents||[]).find(r=>r.owner)?.name||'ID '+m.ownerId)} (ID ${esc(m.ownerId)})</span><span>${Number(m.occupiedCount)||1} / ${Number(m.maxResidents)||1} moradores cadastrados.</span></div>`:''}

        <div class="formactions"><button type="button" class="btn ghost cancel">Cancelar</button><button class="btn primary">${mansion?'Salvar alterações':'Cadastrar mansão'}</button></div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    enhanceAllPanelCoordinates($('#drawer-body'));
    bindMansionSpawnRows();
    updateMansionDoorStatus();

    const updatePermission=()=>{
        const perm=mansionPermissionFromGroup($('#ms-group').value);
        $('#ms-permission').value=perm;
        $('#ms-chest-perm-preview').value=perm;
        $('#ms-garage-perm-preview').value=perm;
    };
    $('#ms-group').oninput=updatePermission;

    const toggleResource=(check,box)=>{
        const enabled=check.checked;
        box.classList.toggle('disabledfields',!enabled);
        box.querySelectorAll('input,select,button').forEach(el=>{
            if(el!==check)el.disabled=!enabled;
        });
    };
    const chestToggle=$('#ms-chest-enabled'),chestFields=$('#ms-chest-fields');
    const garageToggle=$('#ms-garage-enabled'),garageFields=$('#ms-garage-fields');
    const refreshToggles=()=>{
        chestFields.classList.toggle('disabledfields',!chestToggle.checked);
        chestFields.querySelectorAll('input,select,button').forEach(el=>el.disabled=!chestToggle.checked);
        garageFields.classList.toggle('disabledfields',!garageToggle.checked);
        garageFields.querySelectorAll('input,select,button').forEach(el=>el.disabled=!garageToggle.checked);
    };
    chestToggle.onchange=refreshToggles;
    garageToggle.onchange=refreshToggles;
    refreshToggles();

    $$('.mansion-position-capture').forEach(btn=>btn.onclick=async()=>{
        const r=await nui('startMansionPosition',{
            target:btn.dataset.target,
            heading:btn.dataset.heading==='1',
            label:`${btn.dataset.label}: fique no local desejado e pressione E.`
        });
        if(!r?.ok)toast(r?.message||'Não foi possível iniciar o posicionamento.','error');
    });

    $('#mansion-capture-spawn').onclick=async()=>{
        const r=await nui('startMansionPosition',{target:'garageSpawn',heading:true,label:'Posição do veículo: fique no local, olhe para a direção desejada e pressione E.'});
        if(!r?.ok)toast(r?.message||'Não foi possível iniciar o posicionamento.','error');
    };

    $('#mansion-capture-doors').onclick=async()=>{
        const r=await nui('startMansionDoorCapture');
        if(!r?.ok)toast(r?.message||'Não foi possível abrir a criação de trancas.','error');
    };
    $('#mansion-clear-doors').onclick=()=>{
        mansionDoorDraft=[];
        updateMansionDoorStatus();
        toast('Trancas removidas do cadastro atual.');
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const read3=prefix=>({x:Number($(`#${prefix}-x`).value),y:Number($(`#${prefix}-y`).value),z:Number($(`#${prefix}-z`).value)});
        const purchaseCoords=read3('ms-buy');
        if(Object.values(purchaseCoords).some(v=>!Number.isFinite(v)))return toast('Defina corretamente o local de compra.','error');

        const chestEnabled=chestToggle.checked;
        const garageEnabled=garageToggle.checked;
        const spawnCoords=$$('#mansion-spawns .spawnrow').map(row=>({
            x:Number(row.querySelector('.sx').value),
            y:Number(row.querySelector('.sy').value),
            z:Number(row.querySelector('.sz').value),
            w:Number(row.querySelector('.sw').value)
        })).filter(c=>Object.values(c).every(Number.isFinite));

        const data={
            name:$('#ms-name').value.trim(),
            group:$('#ms-group').value.trim(),
            price:Number($('#ms-price').value),
            iptuValue:Number($('#ms-iptu').value),
            voucher:$('#ms-voucher').value,
            maxResidents:Number($('#ms-max').value),
            purchaseCoords,
            chest:{
                enabled:chestEnabled,
                weight:Number($('#ms-chest-weight').value),
                coords:read3('ms-chest')
            },
            garage:{
                enabled:garageEnabled,
                type:$('#ms-garage-type').value,
                blipDistance:Number($('#ms-garage-distance').value),
                coords:read3('ms-garage'),
                spawnCoords
            },
            doors:JSON.parse(JSON.stringify(mansionDoorDraft))
        };

        if(!data.name)return toast('Informe o nome da mansão.','error');
        if(!data.group)return toast('Informe o cargo da mansão.','error');
        if(!mansionPermissionFromGroup(data.group))return toast('Informe um cargo válido.','error');
        if(!Number.isFinite(data.price)||data.price<0)return toast('Informe um valor válido.','error');
        if(!Number.isFinite(data.iptuValue)||data.iptuValue<=0)return toast('Informe um valor válido para o IPTU.','error');
        if(!Number.isInteger(data.maxResidents)||data.maxResidents<1)return toast('Informe uma quantidade válida de moradores.','error');
        if(chestEnabled && (!Number.isFinite(data.chest.weight)||data.chest.weight<=0))return toast('Informe um peso válido para o baú.','error');
        if(chestEnabled && Object.values(data.chest.coords).some(v=>!Number.isFinite(v)))return toast('Defina a posição do baú.','error');
        if(garageEnabled && !data.garage.type)return toast('Selecione o tipo da garagem.','error');
        if(garageEnabled && Object.values(data.garage.coords).some(v=>!Number.isFinite(v)))return toast('Defina o marker da garagem.','error');
        if(garageEnabled && !spawnCoords.length)return toast('Cadastre ao menos uma posição de veículo.','error');

        const r=await nui('saveMansion',{originalId:m.id||'',data});
        if(!r?.ok)return toast(r?.message||'Não foi possível salvar a mansão.','error');
        toast(r.message||'Mansão salva com sucesso.');
        closeDrawer();
        await loadAll(true);
    };
}

function residenceForm(home){
    const interiors=residencesData.interiors||{};
    const type=home?.type||'Casa';
    const options=Object.entries(interiors)
        .filter(([_,i])=>!i.type||i.type===type)
        .map(([name])=>`<option value="${esc(name)}" ${home?.interior===name?'selected':''}>${esc(name)}</option>`)
        .join('');

    $('#drawer-title').textContent=home?`Editar ${home.name}`:'Cadastrar residência';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field">
                <span>Nome / Identificador</span>
                <input id="house-name" value="${esc(home?.name||'')}" placeholder="Homes001" required>
            </label>
            <label class="field">
                <span>Tipo</span>
                <select id="house-type">
                    <option value="Casa" ${type==='Casa'?'selected':''}>Casa</option>
                    <option value="Apartamento" ${type==='Apartamento'?'selected':''}>Apartamento</option>
                </select>
            </label>
        </div>

        <div class="grid2">
            <label class="field">
                <span>Interior</span>
                <select id="house-interior" required>${options}</select>
            </label>
            <label class="field">
                <span>Valor da residência</span>
                <input id="house-price" type="number" min="0" value="${home?.price??0}" required>
            </label>
        </div>

        <div class="grid2">
            <label class="field">
                <span>Quantidade / Slots</span>
                <input id="house-slot" type="number" min="1" value="${home?.slot??1}">
                <small>Em apartamentos define a quantidade de unidades/interfones.</small>
            </label>
            <label class="field">
                <span>Valorização por venda</span>
                <input id="house-trade" type="number" min="0" value="${home?.trade??0}">
            </label>
        </div>

        <div class="sectiontitle">
            <div><b>Local da residência</b><span>Vá até a porta da casa no jogo e capture a posição.</span></div>
            <button type="button" id="house-pos" class="btn primary mini">⌖ Usar minha posição</button>
        </div>
        <div class="grid3">
            <label class="field"><span>X</span><input id="house-x" type="number" step="0.01" value="${home?.x??''}" required></label>
            <label class="field"><span>Y</span><input id="house-y" type="number" step="0.01" value="${home?.y??''}" required></label>
            <label class="field"><span>Z</span><input id="house-z" type="number" step="0.01" value="${home?.z??''}" required></label>
        </div>

        <div class="hint">A residência é salva no <b>residences.json</b> e espelhada na <b>core_residences</b> para manter compatibilidade com o sistema existente.</div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">${home?'Salvar residência':'Criar residência'}</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    const refreshInteriorOptions=()=>{
        const tp=$('#house-type').value;
        const current=$('#house-interior').value;
        const opts=Object.entries(interiors)
            .filter(([_,i])=>!i.type||i.type===tp)
            .map(([name])=>`<option value="${esc(name)}" ${name===current?'selected':''}>${esc(name)}</option>`).join('');
        $('#house-interior').innerHTML=opts;
    };
    $('#house-type').onchange=refreshInteriorOptions;

    $('#house-pos').onclick=async()=>{
        const r=await nui('getPosition');
        if(!r?.ok)return toast(r?.message||'Não foi possível capturar sua posição.','error');
        $('#house-x').value=r.coords.x;
        $('#house-y').value=r.coords.y;
        $('#house-z').value=r.coords.z;
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const data={
            name:$('#house-name').value.trim(),
            type:$('#house-type').value,
            interior:$('#house-interior').value,
            price:Number($('#house-price').value),
            slot:Number($('#house-slot').value)||1,
            trade:Number($('#house-trade').value)||0,
            x:Number($('#house-x').value),
            y:Number($('#house-y').value),
            z:Number($('#house-z').value)
        };

        if(!data.name)return toast('Informe o nome da residência.','error');
        if(!data.interior)return toast('Selecione um interior.','error');
        if([data.x,data.y,data.z].some(v=>!Number.isFinite(v)))return toast('Local da residência inválido.','error');

        await save('saveResidence',{originalName:home?.name||'',data});
    };
}

function residenceInteriorCard(name,data){
    return `<div class="res-interior-row">
        <div>
            <b>${esc(name)}</b>
            <span>${esc(data.type||'Casa')} · R$ ${Number(data.valor||0).toLocaleString('pt-BR')} · ${Number(data.residents)||1} moradores · ${Number(data.vault)||0}kg</span>
        </div>
        <div class="sectionbuttons">
            <button type="button" class="rowbtn edit" data-interior-edit="${enc(name)}">✎</button>
            <button type="button" class="rowbtn del" data-interior-del="${enc(name)}">×</button>
        </div>
    </div>`;
}

function residenceInteriorsList(){
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Interiores das Casas';

    const entries=Object.entries(residencesData.interiors||{}).sort((a,b)=>a[0].localeCompare(b[0]));
    $('#drawer-body').innerHTML=`<div class="form">
        <div class="sectiontitle">
            <div><b>Modelos de interior</b><span>Configure entrada interna, baú, guarda-roupas e capacidades.</span></div>
            <button type="button" id="new-res-interior" class="btn primary mini">＋ Novo interior</button>
        </div>
        <div class="res-interior-list">${entries.map(([n,d])=>residenceInteriorCard(n,d)).join('')}</div>
    </div>`;

    $('#new-res-interior').onclick=()=>residenceInteriorForm(null,null);
    $$('[data-interior-edit]').forEach(b=>{
        b.onclick=()=>{
            const name=dec(b.dataset.interiorEdit);
            residenceInteriorForm(name,residencesData.interiors?.[name]);
        };
    });
    $$('[data-interior-del]').forEach(b=>{
        b.onclick=async()=>{
            const name=dec(b.dataset.interiorDel);
            const r=await nui('deleteResidenceInterior',{name});
            if(!r?.ok)return toast(r?.message||'Não foi possível excluir o interior.','error');
            toast(r.message||'Interior excluído.');
            await loadAll(true);
            residenceInteriorsList();
        };
    });
}

function residenceInteriorForm(name,data){
    const p=data||{};
    const vec=(v,i)=>Array.isArray(v)?(v[i]??''):'';

    $('#drawer-title').textContent=name?`Editar interior ${name}`:'Novo interior';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field"><span>Nome</span><input id="ri-name" value="${esc(name||'')}" placeholder="MinhaCasa" required></label>
            <label class="field"><span>Tipo recomendado</span><select id="ri-type"><option value="Casa" ${p.type!=='Apartamento'?'selected':''}>Casa</option><option value="Apartamento" ${p.type==='Apartamento'?'selected':''}>Apartamento</option></select></label>
        </div>
        <div class="grid4">
            <label class="field"><span>Valor upgrade</span><input id="ri-value" type="number" min="0" value="${p.valor??0}"></label>
            <label class="field"><span>Moradores</span><input id="ri-residents" type="number" min="1" value="${p.residents??1}"></label>
            <label class="field"><span>Baú (kg)</span><input id="ri-vault-size" type="number" min="0" value="${p.vault??0}"></label>
            <label class="field"><span>Geladeira</span><input id="ri-fridge" type="number" min="0" value="${p.fridge??0}"></label>
        </div>

        ${resInteriorCoords('ri-in','Entrada / saída do interior',p.interior)}
        ${resInteriorCoords('ri-vault','Posição do baú',p.vaultCoords)}
        ${resInteriorCoords('ri-wardrobe','Posição do guarda-roupas',p.wardobeCoords)}

        <div class="formactions">
            <button type="button" class="btn ghost back-interiors">Voltar</button>
            <button class="btn primary">Salvar interior</button>
        </div>
    </form>`;

    $('.back-interiors').onclick=residenceInteriorsList;

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const xyz=prefix=>[
            Number($(`#${prefix}-x`).value),
            Number($(`#${prefix}-y`).value),
            Number($(`#${prefix}-z`).value)
        ];
        const payload={
            type:$('#ri-type').value,
            valor:Number($('#ri-value').value)||0,
            residents:Number($('#ri-residents').value)||1,
            vault:Number($('#ri-vault-size').value)||0,
            fridge:Number($('#ri-fridge').value)||0,
            interior:xyz('ri-in'),
            vaultCoords:xyz('ri-vault'),
            wardobeCoords:xyz('ri-wardrobe')
        };
        const all=[...payload.interior,...payload.vaultCoords,...payload.wardobeCoords];
        if(all.some(v=>!Number.isFinite(v)))return toast('Há coordenadas inválidas no interior.','error');

        const newName=$('#ri-name').value.trim();
        const r=await nui('saveResidenceInterior',{originalName:name||'',name:newName,data:payload});
        if(!r?.ok)return toast(r?.message||'Não foi possível salvar o interior.','error');
        toast(r.message||'Interior salvo.');
        await loadAll(true);
        residenceInteriorsList();
    };
}

function resInteriorCoords(prefix,title,v){
    return `<div class="sectiontitle"><div><b>${title}</b></div></div>
    <div class="grid3">
        <label class="field"><span>X</span><input id="${prefix}-x" type="number" step="0.01" value="${Array.isArray(v)?v[0]??'':''}"></label>
        <label class="field"><span>Y</span><input id="${prefix}-y" type="number" step="0.01" value="${Array.isArray(v)?v[1]??'':''}"></label>
        <label class="field"><span>Z</span><input id="${prefix}-z" type="number" step="0.01" value="${Array.isArray(v)?v[2]??'':''}"></label>
    </div>`;
}

function residencesSettingsForm(){
    const s=residencesData.settings||{};
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Configurações das Casas';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field"><span>Webhook do baú das casas</span><input id="res-webhook" value="${esc(s.vaultWebhook||'')}" placeholder="Opcional"></label>
        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Salvar configurações</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const r=await nui('saveResidencesSettings',{vaultWebhook:$('#res-webhook').value.trim()});
        if(!r?.ok)return toast(r?.message||'Erro ao salvar configurações.','error');
        await loadAll(true);
        toast(r.message||'Configurações atualizadas.');
        closeDrawer();
    };
}

function roubocofreForm(){
    const d=JSON.parse(JSON.stringify(roubocofreData||{name:'Roubo a Cofres',settings:{},banks:{}}));
    const s=d.settings||{};
    const bankCount=Object.keys(d.banks||{}).length;

    $('#drawer-title').textContent='Roubo a Cofres';
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid3">
            <label class="field"><span>Policiais mínimos</span><input id="rc-cops" type="number" min="0" value="${s.policeMinimum??0}"></label>
            <label class="field"><span>Permissão polícia</span><input id="rc-perm" value="${esc(s.policePermission||'policia.permissao')}"></label>
            <label class="field"><span>Cooldown (s)</span><input id="rc-cooldown" type="number" min="0" value="${s.cooldownSeconds??1800}"></label>
        </div>

        <div class="grid3">
            <label class="field"><span>Keycard</span><input id="rc-key" value="${esc(s.keycardItem||'keycard')}"></label>
            <label class="field"><span>Qtd. Keycard</span><input id="rc-key-qtd" type="number" min="0" value="${s.keycardAmount??1}"></label>
            <label class="field"><span>Item recompensa</span><input id="rc-reward-item" value="${esc(s.rewardItem||'dinheirosujo')}"></label>
        </div>

        <div class="grid2">
            <label class="field"><span>Recompensa mínima</span><input id="rc-min" type="number" min="0" value="${s.rewardMin??10000}"></label>
            <label class="field"><span>Recompensa máxima</span><input id="rc-max" type="number" min="0" value="${s.rewardMax??20000}"></label>
        </div>

        <div class="grid3">
            <label class="field"><span>Blocos do hacking</span><input id="rc-hack-blocks" type="number" min="1" value="${s.hackBlocks??3}"></label>
            <label class="field"><span>Tempo hacking (s)</span><input id="rc-hack-time" type="number" min="1" value="${s.hackSeconds??60}"></label>
            <label class="field"><span>Distância cancelar</span><input id="rc-cancel-dist" type="number" min="1" step="0.1" value="${s.cancelDistance??30}"></label>
        </div>

        <label class="field"><span>Webhook</span><input id="rc-webhook" value="${esc(s.webhook||'')}" placeholder="Opcional"></label>

        <div class="sectiontitle">
            <div><b>Configuração completa</b><span>${bankCount} bancos configurados. Edite portas, início, dinheiro, drops e horários.</span></div>
        </div>
        <div class="hint">Abaixo está a configuração completa do <b>m_roubocofre</b>. Todas as posições dos bancos, portas dos cofres, pilhas de dinheiro, valores e spawns de Keycard podem ser alterados.</div>
        <label class="field"><span>JSON completo</span><textarea id="rc-json" class="job-json-editor" spellcheck="false">${esc(JSON.stringify(d,null,2))}</textarea></label>

        <div class="formactions">
            <button type="button" class="btn ghost rob-back">Voltar</button>
            <button class="btn primary">Salvar Roubo a Cofres</button>
        </div>
    </form>`;

    $('.rob-back').onclick=robberyHubForm;

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        let full;
        try{full=JSON.parse($('#rc-json').value||'{}')}
        catch{return toast('O JSON possui erro de sintaxe.','error')}

        full.settings=full.settings||{};
        Object.assign(full.settings,{
            policeMinimum:Number($('#rc-cops').value)||0,
            policePermission:$('#rc-perm').value.trim(),
            cooldownSeconds:Number($('#rc-cooldown').value)||0,
            keycardItem:$('#rc-key').value.trim(),
            keycardAmount:Number($('#rc-key-qtd').value)||0,
            rewardItem:$('#rc-reward-item').value.trim(),
            rewardMin:Number($('#rc-min').value)||0,
            rewardMax:Number($('#rc-max').value)||0,
            hackBlocks:Number($('#rc-hack-blocks').value)||1,
            hackSeconds:Number($('#rc-hack-time').value)||1,
            cancelDistance:Number($('#rc-cancel-dist').value)||30,
            webhook:$('#rc-webhook').value.trim()
        });

        if(full.settings.rewardMax<full.settings.rewardMin)
            return toast('Recompensa máxima não pode ser menor que a mínima.','error');

        const r=await nui('saveRoubocofre',full);
        if(!r?.ok)return toast(r?.message||'Erro ao salvar Roubo a Cofres.','error');
        await loadAll(true);
        toast(r.message||'Roubo a Cofres atualizado.');
        roubocofreForm();
    };
}

function joalheriaForm(){
    const d=JSON.parse(JSON.stringify(joalheriaData||{name:'Joalheria',settings:{},rewards:[],displays:[]}));
    const s=d.settings||{};
    $('#drawer-title').textContent='Joalheria';
    $('#drawer').classList.add('open'); $('#overlay').classList.remove('hidden');
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid3">
            <label class="field"><span>Policiais mínimos</span><input id="jw-cops" type="number" min="0" value="${s.policeMinimum??0}"></label>
            <label class="field"><span>Permissão polícia</span><input id="jw-perm" value="${esc(s.policePermission||'policia.permissao')}"></label>
            <label class="field"><span>Cooldown roubo (s)</span><input id="jw-cool" type="number" min="0" value="${s.robberyCooldown??3600}"></label>
        </div>
        <div class="grid3">
            <label class="field"><span>Item Keycard</span><input id="jw-key" value="${esc(s.keycardItem||'keycard')}"></label>
            <label class="field"><span>Qtd. Keycard</span><input id="jw-key-qtd" type="number" min="0" value="${s.keycardAmount??5}"></label>
            <label class="field"><span>Cooldown vitrine (s)</span><input id="jw-display-cool" type="number" min="0" value="${s.displayCooldown??600}"></label>
        </div>
        <div class="grid2">
            <label class="field"><span>Tempo hacking (s)</span><input id="jw-hack" type="number" min="1" value="${s.hackSeconds??10}"></label>
            <label class="field"><span>Blip polícia (s)</span><input id="jw-blip" type="number" min="1" value="${s.policeBlipSeconds??60}"></label>
        </div>
        <div class="sectiontitle"><div><b>Configuração completa</b><span>Posição do hack, C4, vitrines, props, posições do player, armas e recompensas.</span></div></div>
        <div class="hint">A Joalheria possui ${(d.displays||[]).length} vitrines. Todos os dados do roubo podem ser alterados abaixo e são aplicados em tempo real.</div>
        <label class="field"><span>JSON completo da Joalheria</span><textarea id="jw-json" class="job-json-editor" spellcheck="false">${esc(JSON.stringify(d,null,2))}</textarea></label>
        <div class="formactions"><button type="button" class="btn ghost rob-back">Voltar</button><button class="btn primary">Salvar Joalheria</button></div>
    </form>`;
    $('.rob-back').onclick=robberyHubForm;
    $('#form').onsubmit=async e=>{
        e.preventDefault(); let full;
        try{full=JSON.parse($('#jw-json').value||'{}')}catch{return toast('O JSON possui erro de sintaxe.','error')}
        full.settings=full.settings||{};
        Object.assign(full.settings,{
            policeMinimum:Number($('#jw-cops').value)||0,
            policePermission:$('#jw-perm').value.trim(),
            robberyCooldown:Number($('#jw-cool').value)||0,
            keycardItem:$('#jw-key').value.trim(),
            keycardAmount:Number($('#jw-key-qtd').value)||0,
            displayCooldown:Number($('#jw-display-cool').value)||0,
            hackSeconds:Number($('#jw-hack').value)||1,
            policeBlipSeconds:Number($('#jw-blip').value)||1
        });
        const r=await nui('saveJoalheria',full);
        if(!r?.ok)return toast(r?.message||'Erro ao salvar Joalheria.','error');
        await loadAll(true); toast(r.message||'Joalheria atualizada.'); joalheriaForm();
    };
}

function bancoCentralForm(){
    const d=JSON.parse(JSON.stringify(bancoCentralData||{name:'Banco Central',settings:{},banks:[]}));
    const s=d.settings||{};
    const b=d.banks?.[0]||{doors:[],safes:[],money:{},hacking:{}};
    const m=b.money||{};

    $('#drawer-title').textContent='Banco Central';
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid3">
            <label class="field"><span>Policiais mínimos</span><input id="bc-cops" type="number" min="0" value="${s.cops??0}"></label>
            <label class="field"><span>Permissão polícia</span><input id="bc-perm" value="${esc(s.permCops||'policia.permissao')}"></label>
            <label class="field"><span>Reset do roubo (s)</span><input id="bc-reset" type="number" min="1" value="${s.tempoReset??1600}"></label>
        </div>

        <div class="sectiontitle"><div><b>Itens</b><span>Ferramentas necessárias e item recebido como dinheiro.</span></div></div>
        <div class="grid3">
            <label class="field"><span>Explosivo / solda</span><input id="bc-solda" value="${esc(s.solda||'c4')}"></label>
            <label class="field"><span>Quantidade</span><input id="bc-item-qtd" type="number" min="0" value="${s.itemQtd??2}"></label>
            <label class="field"><span>Furadeira</span><input id="bc-drill" value="${esc(s.furadeira||'furadeira')}"></label>
        </div>
        <label class="field"><span>Item dinheiro sujo</span><input id="bc-money-item" value="${esc(s.dinheiroSujo||'dinheirosujo')}"></label>

        <div class="sectiontitle"><div><b>Valores</b><span>Dinheiro disponível e valores retirados por ação.</span></div></div>
        <div class="grid4">
            <label class="field"><span>Dinheiro inicial</span><input id="bc-start-money" type="number" min="0" value="${m.startMoney??0}"></label>
            <label class="field"><span>Valor atual</span><input id="bc-amount" type="number" min="0" value="${m.amount??m.startMoney??0}"></label>
            <label class="field"><span>Mín. por coleta</span><input id="bc-min-take" type="number" min="0" value="${s.minPegar??0}"></label>
            <label class="field"><span>Máx. por coleta</span><input id="bc-max-take" type="number" min="0" value="${s.maxPegar??0}"></label>
        </div>
        <div class="grid2">
            <label class="field"><span>Mín. cofre</span><input id="bc-safe-min" type="number" min="0" value="${s.safeMinimum??0}"></label>
            <label class="field"><span>Máx. cofre</span><input id="bc-safe-max" type="number" min="0" value="${s.safeMax??0}"></label>
        </div>

        <div class="sectiontitle">
            <div><b>Configuração completa do Banco Central</b><span>Portas, posições de solda, cofres, câmeras, hacking, bags, caixas e spawns de furadeira.</span></div>
        </div>
        <div class="hint">Os campos acima são os valores usados com mais frequência. Abaixo você pode editar <b>todo o restante do roubo</b>, incluindo todas as coordenadas.</div>
        <label class="field">
            <span>JSON completo</span>
            <textarea id="bc-json" class="job-json-editor" spellcheck="false">${esc(JSON.stringify(d,null,2))}</textarea>
        </label>

        <div class="formactions">
            <button type="button" class="btn ghost rob-back">Voltar</button>
            <button class="btn primary">Salvar Banco Central</button>
        </div>
    </form>`;

    $('.rob-back').onclick=robberyHubForm;

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        let full;
        try{full=JSON.parse($('#bc-json').value||'{}')}
        catch{return toast('O JSON completo possui erro de sintaxe.','error')}

        full.settings=full.settings||{};
        full.banks=Array.isArray(full.banks)?full.banks:[];
        if(!full.banks[0])full.banks[0]={doors:[],safes:[],money:{},hacking:{}};
        full.banks[0].money=full.banks[0].money||{};

        Object.assign(full.settings,{
            cops:Number($('#bc-cops').value)||0,
            permCops:$('#bc-perm').value.trim(),
            tempoReset:Number($('#bc-reset').value)||1,
            solda:$('#bc-solda').value.trim(),
            itemQtd:Number($('#bc-item-qtd').value)||0,
            furadeira:$('#bc-drill').value.trim(),
            dinheiroSujo:$('#bc-money-item').value.trim(),
            minPegar:Number($('#bc-min-take').value)||0,
            maxPegar:Number($('#bc-max-take').value)||0,
            safeMinimum:Number($('#bc-safe-min').value)||0,
            safeMax:Number($('#bc-safe-max').value)||0
        });
        full.banks[0].money.startMoney=Number($('#bc-start-money').value)||0;
        full.banks[0].money.amount=Number($('#bc-amount').value)||0;

        if(full.settings.maxPegar<full.settings.minPegar)return toast('Máximo por coleta não pode ser menor que o mínimo.','error');
        if(full.settings.safeMax<full.settings.safeMinimum)return toast('Máximo do cofre não pode ser menor que o mínimo.','error');

        const r=await nui('saveBancoCentral',full);
        if(!r?.ok)return toast(r?.message||'Erro ao salvar Banco Central.','error');
        await loadAll(true);
        toast(r.message||'Banco Central atualizado.');
        bancoCentralForm();
    };
}

function robberyHubForm(){
    const types=Object.keys(robberiesData.setups||{});
    $('#drawer-title').textContent='Roubos de Comércio';
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');

    $('#drawer-body').innerHTML=`<div class="form">
        <div class="hint">Este é o primeiro dos 4 sistemas da aba Roubos. Cada próximo script ficará como uma opção independente aqui.</div>
        <div class="robbery-type-grid">
            ${types.map(type=>{
                const count=(robberiesData.locations||[]).filter(x=>x.type===type).length;
                const s=robberiesData.setups[type]||{};
                return `<button type="button" class="robbery-type-card" data-type="${esc(type)}">
                    <b>${esc(type)}</b>
                    <span>${count} locais</span>
                    <small>${s.tempo||0}s · cooldown ${s.tempoEspera||0}min · ${s.lspd||0} policiais</small>
                </button>`;
            }).join('')}
        </div>
        <div class="sectiontitle"><div><b>Configurações gerais</b><span>Permissões e duração do alerta policial.</span></div></div>
        <button type="button" id="rob-global" class="btn ghost">⚙ Configurações gerais</button>
    </div>`;

    $$('.robbery-type-card').forEach(b=>b.onclick=()=>robberyTypeForm(b.dataset.type));
    $('#rob-global').onclick=robberyGlobalForm;
}

function robberyItemRows(items={},kind='reward'){
    return Object.entries(items||{}).map(([name,v])=>`<div class="rob-item-row">
        <input class="rob-item-name" value="${esc(name)}" placeholder="item">
        ${kind==='reward'
            ?`<input class="rob-item-min" type="number" min="0" value="${v.min??0}" placeholder="Mínimo">
              <input class="rob-item-max" type="number" min="0" value="${v.max??0}" placeholder="Máximo">`
            :`<input class="rob-item-qtd" type="number" min="1" value="${v.qtd??1}" placeholder="Qtd">`
        }
        <button type="button" class="remove">×</button>
    </div>`).join('');
}

function bindRobItemRows(root){
    $$(root+' .remove').forEach(b=>b.onclick=()=>b.closest('.rob-item-row').remove());
}

function robberyTypeForm(type){
    const setup=JSON.parse(JSON.stringify(robberiesData.setups?.[type]||{}));
    const locs=(robberiesData.locations||[]).filter(x=>x.type===type).sort((a,b)=>Number(a.id)-Number(b.id));

    $('#drawer-title').textContent=type;
    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid3">
            <label class="field"><span>Tempo do roubo (s)</span><input id="rob-time" type="number" min="1" value="${setup.tempo??60}"></label>
            <label class="field"><span>Cooldown (min)</span><input id="rob-cooldown" type="number" min="0" value="${setup.tempoEspera??5}"></label>
            <label class="field"><span>Policiais mínimos</span><input id="rob-police" type="number" min="0" value="${setup.lspd??0}"></label>
        </div>

        <label class="field"><span>Webhook</span><input id="rob-webhook" value="${esc(robberiesData.webhooks?.[type]||'')}" placeholder="Opcional"></label>

        <div class="sectiontitle">
            <div><b>Recompensas</b><span>Itens entregues ao finalizar o roubo.</span></div>
            <button type="button" id="rob-add-reward" class="btn ghost mini">＋ Item</button>
        </div>
        <div id="rob-rewards">${robberyItemRows(setup.items||{},'reward')}</div>

        <div class="sectiontitle">
            <div><b>Itens necessários</b><span>Itens consumidos ao iniciar.</span></div>
            <button type="button" id="rob-add-required" class="btn ghost mini">＋ Item</button>
        </div>
        <div id="rob-required">${robberyItemRows(setup.itemsNecessarios||{},'required')}</div>

        <div class="sectiontitle">
            <div><b>Locais</b><span>${locs.length} pontos deste tipo.</span></div>
            <button type="button" id="rob-add-location" class="btn primary mini">＋ Novo local</button>
        </div>
        <div class="rob-location-list">
            ${locs.map(v=>`<div class="rob-location-row">
                <div><b>#${v.id}</b><span>${f(v.x)}, ${f(v.y)}, ${f(v.z)}</span></div>
                <div class="sectionbuttons">
                    <button type="button" class="rowbtn tp" data-rob-tp="${v.id}" title="Teleportar">⌖</button>
                    <button type="button" class="rowbtn edit" data-rob-edit="${v.id}" title="Editar">✎</button>
                    <button type="button" class="rowbtn del" data-rob-del="${v.id}" title="Excluir">×</button>
                </div>
            </div>`).join('')}
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost rob-back">Voltar</button>
            <button class="btn primary">Salvar configurações</button>
        </div>
    </form>`;

    bindRobItemRows('#rob-rewards');
    bindRobItemRows('#rob-required');
    $('.rob-back').onclick=robberyHubForm;

    $('#rob-add-reward').onclick=()=>{
        $('#rob-rewards').insertAdjacentHTML('beforeend',robberyItemRows({'':{min:0,max:0}},'reward'));
        bindRobItemRows('#rob-rewards');
    };
    $('#rob-add-required').onclick=()=>{
        $('#rob-required').insertAdjacentHTML('beforeend',robberyItemRows({'':{qtd:1}},'required'));
        bindRobItemRows('#rob-required');
    };
    $('#rob-add-location').onclick=()=>robberyLocationForm(type,null);

    $$('[data-rob-edit]').forEach(b=>b.onclick=()=>{
        const v=locs.find(x=>Number(x.id)===Number(b.dataset.robEdit));
        robberyLocationForm(type,v);
    });
    $$('[data-rob-tp]').forEach(b=>b.onclick=async()=>{
        const v=locs.find(x=>Number(x.id)===Number(b.dataset.robTp));
        if(v)await nui('teleport',{x:v.x,y:v.y,z:v.z});
    });
    $$('[data-rob-del]').forEach(b=>b.onclick=async()=>{
        const id=Number(b.dataset.robDel);
        const r=await nui('deleteRobberyLocation',{type,id});
        if(!r?.ok)return toast(r?.message||'Erro ao excluir.','error');
        await loadAll(true); toast(r.message||'Local excluído.'); robberyTypeForm(type);
    });

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const items={};
        $$('#rob-rewards .rob-item-row').forEach(r=>{
            const name=r.querySelector('.rob-item-name').value.trim();
            if(name)items[name]={min:Number(r.querySelector('.rob-item-min').value)||0,max:Number(r.querySelector('.rob-item-max').value)||0};
        });
        const required={};
        $$('#rob-required .rob-item-row').forEach(r=>{
            const name=r.querySelector('.rob-item-name').value.trim();
            if(name)required[name]={qtd:Math.max(1,Number(r.querySelector('.rob-item-qtd').value)||1)};
        });

        const data={
            items,
            itemsNecessarios:required,
            tempo:Number($('#rob-time').value),
            tempoEspera:Number($('#rob-cooldown').value),
            lspd:Number($('#rob-police').value),
            qntditem:Number(setup.qntditem)||0,
            webhook:$('#rob-webhook').value.trim()
        };
        const r=await nui('saveRobberySetup',{type,data});
        if(!r?.ok)return toast(r?.message||'Erro ao salvar.','error');
        await loadAll(true); toast(r.message||'Configuração salva.'); robberyTypeForm(type);
    };
}

function robberyLocationForm(type,v){
    const ids=(robberiesData.locations||[]).filter(x=>x.type===type).map(x=>Number(x.id)||0);
    const nextId=ids.length?Math.max(...ids)+1:1;

    $('#drawer-title').textContent=v?`Editar ${type} #${v.id}`:`Novo local - ${type}`;
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field"><span>Tipo</span><input value="${esc(type)}" disabled></label>
            <label class="field"><span>ID</span><input id="rob-loc-id" type="number" min="1" value="${v?.id??nextId}"></label>
        </div>
        <div class="sectiontitle">
            <div><b>Posição</b><span>Coordenadas e direção do roubo.</span></div>
            <button type="button" id="rob-use-pos" class="btn primary mini">⌖ Usar minha posição</button>
        </div>
        <div class="grid4">
            <label class="field"><span>X</span><input id="rob-x" type="number" step="0.01" value="${v?.x??''}"></label>
            <label class="field"><span>Y</span><input id="rob-y" type="number" step="0.01" value="${v?.y??''}"></label>
            <label class="field"><span>Z</span><input id="rob-z" type="number" step="0.01" value="${v?.z??''}"></label>
            <label class="field"><span>Heading</span><input id="rob-h" type="number" step="0.01" value="${v?.h??0}"></label>
        </div>
        <div class="formactions">
            <button type="button" class="btn ghost rob-back">Voltar</button>
            <button class="btn primary">${v?'Salvar local':'Criar local'}</button>
        </div>
    </form>`;

    $('.rob-back').onclick=()=>robberyTypeForm(type);
    $('#rob-use-pos').onclick=async()=>{
        const r=await nui('getPosition4');
        if(!r?.ok)return toast(r?.message||'Não foi possível capturar a posição.','error');
        $('#rob-x').value=r.coords.x; $('#rob-y').value=r.coords.y; $('#rob-z').value=r.coords.z; $('#rob-h').value=r.coords.w??0;
    };
    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const data={type,id:Number($('#rob-loc-id').value),x:Number($('#rob-x').value),y:Number($('#rob-y').value),z:Number($('#rob-z').value),h:Number($('#rob-h').value)};
        const ev=v?'updateRobberyLocation':'addRobberyLocation';
        const payload=v?{originalType:v.type,originalId:v.id,data}:data;
        const r=await nui(ev,payload);
        if(!r?.ok)return toast(r?.message||'Erro ao salvar local.','error');
        await loadAll(true); toast(r.message||'Local salvo.'); robberyTypeForm(type);
    };
}

function robberyGlobalForm(){
    const s=robberiesData.settings||{};
    $('#drawer-title').textContent='Configurações gerais - Roubos';
    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field"><span>Permissão da polícia</span><input id="rob-police-perm" value="${esc(s.policePermission||'policia.permissao')}"></label>
        <label class="field"><span>Permissões bloqueadas</span><input id="rob-blocked" value="${esc((s.blockedPermissions||[]).join(', '))}" placeholder="policia.permissao, medico.permissao"></label>
        <label class="field"><span>Duração do blip policial (segundos)</span><input id="rob-blip-time" type="number" min="1" value="${s.policeBlipSeconds??45}"></label>
        <div class="formactions">
            <button type="button" class="btn ghost rob-back">Voltar</button>
            <button class="btn primary">Salvar</button>
        </div>
    </form>`;
    $('.rob-back').onclick=robberyHubForm;
    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const r=await nui('saveRobberyGlobalSettings',{
            policePermission:$('#rob-police-perm').value.trim(),
            blockedPermissions:$('#rob-blocked').value.split(',').map(x=>x.trim()).filter(Boolean),
            policeBlipSeconds:Number($('#rob-blip-time').value)
        });
        if(!r?.ok)return toast(r?.message||'Erro ao salvar.','error');
        await loadAll(true);toast(r.message||'Configuração salva.');robberyGlobalForm();
    };
}

function jobLevelRows(job){
    const levels=Math.max(1,Number(job.total_nivel)||1);
    const xp=Array.isArray(job.xp_for_level)?job.xp_for_level:[];
    const pay=Array.isArray(job.payment_for_level)?job.payment_for_level:[];

    return Array.from({length:levels},(_,i)=>{
        const level=i+1;
        const p=pay[i]||[];
        return `<div class="job-level-row" data-level="${level}">
            <b>Nível ${level}</b>
            <label class="field"><span>XP para próximo</span><input class="job-xp" type="number" min="0" value="${level<levels?(xp[i]??0):0}" ${level===levels?'disabled':''}></label>
            <label class="field"><span>Pagamento mín.</span><input class="job-pay-min" type="number" min="0" value="${p[0]??0}"></label>
            <label class="field"><span>Pagamento máx.</span><input class="job-pay-max" type="number" min="0" value="${p[1]??0}"></label>
        </div>`;
    }).join('');
}

function renderJobLevels(){
    const box=$('#job-levels');
    if(!box)return;
    const total=Math.max(1,Number($('#job-total-levels').value)||1);
    const current=box._jobDraft||{xp_for_level:[],payment_for_level:[]};
    current.total_nivel=total;
    box.innerHTML=jobLevelRows(current);
}

function jobForm(entry){
    const name=entry?.name||'';
    const job=JSON.parse(JSON.stringify(entry?.data||{}));
    const extra=JSON.parse(JSON.stringify(entry?.extra||{}));

    $('#drawer-title').textContent=`Editar ${name}`;

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field">
                <span>Emprego</span>
                <input value="${esc(name)}" disabled>
            </label>
            <label class="field">
                <span>Total de níveis</span>
                <input id="job-total-levels" type="number" min="1" max="50" value="${job.total_nivel??1}" required>
            </label>
        </div>

        <div class="sectiontitle">
            <div><b>Local inicial</b><span>Onde o jogador inicia este emprego.</span></div>
            <button type="button" id="job-use-position" class="btn primary mini">⌖ Usar minha posição</button>
        </div>
        <div class="grid3">
            <label class="field"><span>X</span><input id="job-x" type="number" step="0.01" value="${job.inicio?.[0]??''}" required></label>
            <label class="field"><span>Y</span><input id="job-y" type="number" step="0.01" value="${job.inicio?.[1]??''}" required></label>
            <label class="field"><span>Z</span><input id="job-z" type="number" step="0.01" value="${job.inicio?.[2]??''}" required></label>
        </div>

        <div class="sectiontitle"><div><b>Níveis e pagamentos</b><span>Valores utilizados pelo sistema de progressão do emprego.</span></div></div>
        <div id="job-levels">${jobLevelRows(job)}</div>

        <div class="sectiontitle">
            <div><b>Uniformes</b><span>Capture a roupa completa atual do personagem.</span></div>
        </div>
        <div class="job-uniform-actions">
            <button type="button" id="job-capture-uniform" class="btn ghost">♙ Capturar uniforme atual</button>
            <span id="job-uniform-status" class="muted">${
                job.uniforme?.masculino&&job.uniforme?.feminino?'Masculino e feminino definidos':
                job.uniforme?.masculino?'Masculino definido':
                job.uniforme?.feminino?'Feminino definido':'Nenhum uniforme definido'
            }</span>
        </div>

        <div class="sectiontitle">
            <div>
                <b>Configuração específica</b>
                <span>Rotas, itens, veículos, locais de venda, tempos e demais opções exclusivas deste emprego.</span>
            </div>
        </div>
        <div class="hint">Esta área representa <b>todas as configurações específicas</b> deste emprego no jobs.json. Você pode alterar qualquer valor, rota, veículo, item ou local.</div>
        <label class="field">
            <span>JSON avançado</span>
            <textarea id="job-extra-json" class="job-json-editor" spellcheck="false">${esc(JSON.stringify(extra,null,2))}</textarea>
        </label>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Salvar emprego</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    const levelsBox=$('#job-levels');
    levelsBox._jobDraft=job;
    $('#job-total-levels').onchange=()=>{
        const xp=$$('#job-levels .job-level-row').map(r=>Number(r.querySelector('.job-xp')?.value)||0);
        const pay=$$('#job-levels .job-level-row').map(r=>[Number(r.querySelector('.job-pay-min')?.value)||0,Number(r.querySelector('.job-pay-max')?.value)||0]);
        levelsBox._jobDraft={...job,xp_for_level:xp,payment_for_level:pay,total_nivel:Number($('#job-total-levels').value)};
        renderJobLevels();
    };

    $('#job-use-position').onclick=async()=>{
        const r=await nui('getPosition');
        if(!r?.ok)return toast(r?.message||'Não foi possível capturar a posição.','error');
        $('#job-x').value=r.coords.x;
        $('#job-y').value=r.coords.y;
        $('#job-z').value=r.coords.z;
    };

    $('#job-capture-uniform').onclick=async()=>{
        const r=await nui('captureJobUniform',{name});
        if(!r?.ok)return toast(r?.message||'Não foi possível capturar o uniforme.','error');
        if(r.data)job.uniforme=r.data;
        $('#job-uniform-status').textContent=r.message||'Uniforme capturado.';
        toast(r.message||'Uniforme capturado.');
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        let parsedExtra;
        try{
            parsedExtra=JSON.parse($('#job-extra-json').value||'{}');
        }catch(err){
            return toast('O JSON da configuração específica possui erro de sintaxe.','error');
        }

        const total=Math.max(1,Number($('#job-total-levels').value)||1);
        const rows=$$('#job-levels .job-level-row');
        const xp=[];
        const payment=[];

        rows.forEach((r,i)=>{
            if(i<total-1)xp.push(Number(r.querySelector('.job-xp')?.value)||0);
            const mn=Number(r.querySelector('.job-pay-min')?.value)||0;
            const mx=Number(r.querySelector('.job-pay-max')?.value)||0;
            if(mn>0||mx>0)payment.push([mn,mx]);
            else if((job.payment_for_level||[]).length)payment.push([0,0]);
        });

        const data={
            index:name,
            inicio:[Number($('#job-x').value),Number($('#job-y').value),Number($('#job-z').value)],
            total_nivel:total,
            xp_for_level:xp,
            payment_for_level:payment,
            uniforme:job.uniforme||{}
        };

        if(data.inicio.some(v=>!Number.isFinite(v)))return toast('Local inicial inválido.','error');
        if(payment.some(p=>p[1]<p[0]))return toast('Pagamento máximo não pode ser menor que o mínimo.','error');

        await save('updateJob',{name,job:data,extra:parsedExtra});
    };
}

function jobsGlobalForm(){
    const c=jobsData.central||[];
    const n=jobsData.npc||[];

    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Central de Empregos';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="sectiontitle">
            <div><b>Central de Empregos</b><span>Local usado quando o jogador precisa assinar a carteira.</span></div>
            <button type="button" id="jobs-central-pos" class="btn primary mini">⌖ Usar minha posição</button>
        </div>
        <div class="grid3">
            <label class="field"><span>X</span><input id="jobs-cx" type="number" step="0.01" value="${c[0]??''}"></label>
            <label class="field"><span>Y</span><input id="jobs-cy" type="number" step="0.01" value="${c[1]??''}"></label>
            <label class="field"><span>Z</span><input id="jobs-cz" type="number" step="0.01" value="${c[2]??''}"></label>
        </div>

        <div class="sectiontitle">
            <div><b>NPC da Central</b><span>Posição e direção do NPC.</span></div>
            <button type="button" id="jobs-npc-pos" class="btn primary mini">⌖ Usar minha posição</button>
        </div>
        <div class="grid4">
            <label class="field"><span>X</span><input id="jobs-nx" type="number" step="0.01" value="${n[0]??''}"></label>
            <label class="field"><span>Y</span><input id="jobs-ny" type="number" step="0.01" value="${n[1]??''}"></label>
            <label class="field"><span>Z</span><input id="jobs-nz" type="number" step="0.01" value="${n[2]??''}"></label>
            <label class="field"><span>Heading</span><input id="jobs-nh" type="number" step="0.01" value="${n[3]??0}"></label>
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Salvar configurações</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    $('#jobs-central-pos').onclick=async()=>{
        const r=await nui('getPosition');
        if(!r?.ok)return toast(r?.message||'Falha ao capturar posição.','error');
        $('#jobs-cx').value=r.coords.x; $('#jobs-cy').value=r.coords.y; $('#jobs-cz').value=r.coords.z;
    };

    $('#jobs-npc-pos').onclick=async()=>{
        const r=await nui('getPosition');
        if(!r?.ok)return toast(r?.message||'Falha ao capturar posição.','error');
        $('#jobs-nx').value=r.coords.x; $('#jobs-ny').value=r.coords.y; $('#jobs-nz').value=r.coords.z;
        $('#jobs-nh').value=r.coords.w??0;
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        await save('saveJobsGlobal',{
            central:[Number($('#jobs-cx').value),Number($('#jobs-cy').value),Number($('#jobs-cz').value)],
            npc:[Number($('#jobs-nx').value),Number($('#jobs-ny').value),Number($('#jobs-nz').value),Number($('#jobs-nh').value)]
        });
    };
}

function safePolygonCard(poly={},index=0){
    const coords=poly.coords||[];
    return `<div class="safe-poly-card" data-index="${index}">
        <div class="sectiontitle">
            <div>
                <b>Polígono #${index+1}</b>
                <span><strong class="safe-point-count">${coords.length}</strong> pontos capturados</span>
            </div>
            <div class="sectionbuttons">
                <button type="button" class="btn primary mini safe-draw-poly">⌖ ${coords.length?'Redesenhar':'Desenhar'} no jogo</button>
                <button type="button" class="btn ghost mini safe-remove-poly">× Remover</button>
            </div>
        </div>

        <div class="grid2">
            <label class="field">
                <span>minZ</span>
                <input class="safe-minz" type="number" step="0.01" value="${poly.minZ??''}" placeholder="Altura mínima" required>
            </label>
            <label class="field">
                <span>maxZ</span>
                <input class="safe-maxz" type="number" step="0.01" value="${poly.maxZ??''}" placeholder="Altura máxima" required>
            </label>
        </div>

        <input class="safe-coords-json" type="hidden" value="${esc(JSON.stringify(coords))}">

        <div class="safe-poly-summary">
            ${coords.length
                ?`<span>Primeiro ponto: <b>${f(coords[0]?.x)}, ${f(coords[0]?.y)}</b></span>
                  <span>Último ponto: <b>${f(coords[coords.length-1]?.x)}, ${f(coords[coords.length-1]?.y)}</b></span>`
                :'<span class="muted">Clique em “Desenhar no jogo” e marque pelo menos 3 vértices.</span>'
            }
        </div>
    </div>`;
}

function reindexSafePolygons(){
    $$('#safe-polygons .safe-poly-card').forEach((card,index)=>{
        card.dataset.index=index;
        const title=card.querySelector('.sectiontitle b');
        if(title)title.textContent=`Polígono #${index+1}`;
    });
}

function bindSafePolygons(){
    $$('#safe-polygons .safe-poly-card').forEach(card=>{
        const index=()=>Number(card.dataset.index);

        card.querySelector('.safe-draw-poly').onclick=async()=>{
            const r=await nui('startSafeZonePolygon',{target:index()});
            if(!r?.ok)toast(r?.message||'Não foi possível iniciar o desenho.','error');
        };

        card.querySelector('.safe-remove-poly').onclick=()=>{
            if($$('#safe-polygons .safe-poly-card').length<=1){
                return toast('A SafeZone precisa manter pelo menos um polígono.','error');
            }
            card.remove();
            reindexSafePolygons();
        };
    });
}

function safeZoneForm(zone){
    $('#drawer-title').textContent=zone?`Editar ${zone.name}`:'Cadastrar SafeZone';

    const polygons=zone?.zones?.length?zone.zones:[{minZ:'',maxZ:'',coords:[]}];

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field">
                <span>Nome da SafeZone</span>
                <input id="safe-name" value="${esc(zone?.name||'')}" placeholder="Praca" required>
            </label>

            <label class="checkrow safe-debug-row">
                <input id="safe-debug" type="checkbox" ${zone?.debug?'checked':''}>
                Ativar Debug PolyZone
            </label>
        </div>

        ${zone?`<div class="hint">Você pode renomear a SafeZone. As referências da whitelist devem usar o novo nome.</div>`:''}

        <div class="sectiontitle">
            <div>
                <b>Polígonos da SafeZone</b>
                <span>Uma SafeZone pode ser formada por uma ou várias áreas conectadas.</span>
            </div>
            <button type="button" id="safe-add-poly" class="btn ghost mini">＋ Adicionar polígono</button>
        </div>

        <div id="safe-polygons">${polygons.map((p,i)=>safePolygonCard(p,i)).join('')}</div>

        <div class="hint">
            Para desenhar: clique em <b>Desenhar no jogo</b>, caminhe pelos limites da área e pressione
            <b>E</b> em cada vértice. Use <b>BACKSPACE</b> para concluir e <b>X</b> para cancelar.
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">${zone?'Salvar SafeZone':'Criar SafeZone'}</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    bindSafePolygons();

    $('#safe-add-poly').onclick=()=>{
        const index=$$('#safe-polygons .safe-poly-card').length;
        $('#safe-polygons').insertAdjacentHTML('beforeend',safePolygonCard({coords:[]},index));
        bindSafePolygons();
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const zones=$$('#safe-polygons .safe-poly-card').map(card=>{
            let coords=[];
            try{coords=JSON.parse(card.querySelector('.safe-coords-json').value||'[]')}catch{}

            return {
                minZ:Number(card.querySelector('.safe-minz').value),
                maxZ:Number(card.querySelector('.safe-maxz').value),
                coords
            };
        });

        if(zones.some(p=>!Number.isFinite(p.minZ)||!Number.isFinite(p.maxZ))){
            return toast('Defina minZ e maxZ em todos os polígonos.','error');
        }
        if(zones.some(p=>p.minZ>=p.maxZ)){
            return toast('O minZ precisa ser menor que o maxZ.','error');
        }
        if(zones.some(p=>(p.coords||[]).length<3)){
            return toast('Todo polígono precisa de pelo menos 3 pontos.','error');
        }

        const data={
            name:$('#safe-name').value.trim(),
            debug:$('#safe-debug').checked,
            zones
        };

        if(!data.name)return toast('Informe o nome da SafeZone.','error');

        if(zone){
            await save('updateSafeZone',{originalName:zone.name,data});
        }else{
            await save('createSafeZone',data);
        }
    };
}

function safeWhitelistRow(entry={}){
    const options=safeZones
        .map(z=>`<option value="${esc(z.name)}" ${String(entry.zone||'')===String(z.name)?'selected':''}>${esc(z.name)}</option>`)
        .join('');

    return `<div class="safe-wl-row">
        <input class="safe-wl-job" value="${esc(entry.job||'')}" placeholder="policia">
        <select class="safe-wl-zone">
            <option value="">Selecione a SafeZone...</option>
            ${options}
        </select>
        <input class="safe-wl-grade" type="number" step="1" value="${entry.minGrade??0}" placeholder="Grade">
        <button type="button" class="remove">×</button>
    </div>`;
}

function bindSafeWhitelist(){
    $$('#safe-whitelist .remove').forEach(b=>b.onclick=()=>b.closest('.safe-wl-row').remove());
}

function safeZoneSettingsForm(){
    const s=safeZoneSettings||{};

    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Configurações SafeZone';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="grid2">
            <label class="field">
                <span>CheckLoopTime (ms)</span>
                <input id="safe-loop" type="number" min="50" step="50" value="${s.checkLoopTime??1000}" required>
            </label>

            <label class="checkrow">
                <input id="safe-use-whitelist" type="checkbox" ${s.useWhitelist?'checked':''}>
                Usar whitelist de cargos
            </label>
        </div>

        <label class="checkrow">
            <input id="safe-use-esx" type="checkbox" ${s.useESX?'checked':''}>
            Integração ESX
        </label>

        <div class="sectiontitle">
            <div>
                <b>Whitelist / exceções</b>
                <span>Cargos autorizados a atacar dentro de SafeZones específicas.</span>
            </div>
            <button type="button" id="safe-add-wl" class="btn ghost mini">＋ Adicionar exceção</button>
        </div>

        <div id="safe-whitelist">${(safeZoneWhitelist||[]).map(safeWhitelistRow).join('')}</div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Salvar configurações</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    bindSafeWhitelist();

    $('#safe-add-wl').onclick=()=>{
        $('#safe-whitelist').insertAdjacentHTML('beforeend',safeWhitelistRow());
        bindSafeWhitelist();
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const whitelist=$$('#safe-whitelist .safe-wl-row').map(row=>({
            job:row.querySelector('.safe-wl-job').value.trim(),
            zone:row.querySelector('.safe-wl-zone').value,
            minGrade:Number(row.querySelector('.safe-wl-grade').value)||0
        })).filter(x=>x.job&&x.zone);

        await save('saveSafeZoneSettings',{
            useESX:$('#safe-use-esx').checked,
            useWhitelist:$('#safe-use-whitelist').checked,
            checkLoopTime:Number($('#safe-loop').value),
            whitelist
        });
    };
}

function desItemRow(item={}){
    return `<div class="des-item-row">
        <input class="des-item-name" value="${esc(item.item||'')}" placeholder="lockpick">
        <input class="des-item-qtd" type="number" min="1" step="1" value="${item.qtd??1}" placeholder="Qtd">
        <button type="button" class="remove">×</button>
    </div>`;
}

function desPositionBlock(prefix,title,coords,heading=false){
    return `<div class="des-pos-card">
        <div class="sectiontitle">
            <div>
                <b>${esc(title)}</b>
                <span>${heading?'Posição e direção atual do personagem.':'Posição atual do personagem.'}</span>
            </div>
            <button
                type="button"
                class="btn primary mini des-capture-position"
                data-prefix="${prefix}"
                data-label="${esc(title)}"
                data-heading="${heading?'1':'0'}"
            >⌖ Definir no jogo</button>
        </div>

        <div class="${heading?'grid4':'grid3'}">
            <label class="field"><span>X</span><input id="${prefix}-x" type="number" step="0.01" value="${coords?.x??''}" required></label>
            <label class="field"><span>Y</span><input id="${prefix}-y" type="number" step="0.01" value="${coords?.y??''}" required></label>
            <label class="field"><span>Z</span><input id="${prefix}-z" type="number" step="0.01" value="${coords?.z??''}" required></label>
            ${heading?`<label class="field"><span>Heading</span><input id="${prefix}-w" type="number" step="0.01" value="${coords?.w??''}" required></label>`:''}
        </div>
    </div>`;
}

function bindDesmanchePositions(){
    $$('.des-capture-position').forEach(btn=>{
        btn.onclick=async()=>{
            const target=btn.dataset.prefix;
            const label=btn.dataset.label;
            const heading=btn.dataset.heading==='1';

            const r=await nui('startDesmanchePosition',{
                target,
                label:`${label}: fique no local desejado${heading?' e olhe para a direção correta':''}.`,
                heading
            });

            if(!r?.ok){
                toast(r?.message||'Não foi possível iniciar o posicionamento.','error');
            }
        };
    });
}

function bindDesmancheItems(){
    $$('#des-items .remove').forEach(btn=>{
        btn.onclick=()=>btn.closest('.des-item-row').remove();
    });
}

function desmancheForm(d){
    $('#drawer-title').textContent=d?`Editar ${d.name}`:'Cadastrar desmanche';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field">
            <span>Identificador</span>
            <input id="des-name" value="${esc(d?.name||'')}" placeholder="roxos" required>
        </label>

        ${d?`<div class="hint">O identificador pode ser renomeado. Ex.: <b>${esc(d.name)}</b> → <b>Roxos</b>.</div>`:''}

        <div class="grid2">
            <label class="field">
                <span>Permissão</span>
                <input id="des-perm" value="${esc(d?.permissao||'')}" placeholder="perm.roxos" required>
            </label>

            <label class="checkrow des-check">
                <input id="des-needs-item" type="checkbox" ${d?.precisa_de_item?'checked':''}>
                Exigir item para iniciar
            </label>
        </div>

        <div class="sectiontitle">
            <div>
                <b>Itens necessários</b>
                <span>Quando a exigência estiver desativada, estes itens não são consumidos.</span>
            </div>
            <button type="button" id="des-add-item" class="btn ghost mini">＋ Adicionar item</button>
        </div>

        <div id="des-items">${
            (d?.itens_necessarios?.length?d.itens_necessarios:[{item:'lockpick',qtd:1}])
                .map(desItemRow).join('')
        }</div>

        <div class="hint">
            O script original precisa manter ao menos uma linha de item internamente.
            Se <b>Exigir item</b> estiver desmarcado, nenhum item será retirado do jogador.
        </div>

        ${desPositionBlock('des-start','1. Início do desmanche',d?.inicio,false)}
        ${desPositionBlock('des-vehicle','2. Local do veículo',d?.local_veiculo,false)}
        ${desPositionBlock('des-tools','3. Local das ferramentas',d?.local_ferramentas,true)}
        ${desPositionBlock('des-finish','4. Local de finalização',d?.local_finalizar,false)}

        <label class="field">
            <span>Webhook de log</span>
            <input id="des-webhook" value="${esc(d?.log_webhook||'')}" placeholder="Opcional">
        </label>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">${d?'Salvar desmanche':'Cadastrar desmanche'}</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    bindDesmanchePositions();
    bindDesmancheItems();

    $('#des-add-item').onclick=()=>{
        $('#des-items').insertAdjacentHTML('beforeend',desItemRow());
        bindDesmancheItems();
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const read3=prefix=>({
            x:Number($(`#${prefix}-x`).value),
            y:Number($(`#${prefix}-y`).value),
            z:Number($(`#${prefix}-z`).value)
        });

        const read4=prefix=>({
            ...read3(prefix),
            w:Number($(`#${prefix}-w`).value)
        });

        const itens_necessarios=$$('#des-items .des-item-row')
            .map(row=>({
                item:row.querySelector('.des-item-name').value.trim(),
                qtd:Number(row.querySelector('.des-item-qtd').value)
            }))
            .filter(i=>i.item && Number.isFinite(i.qtd) && i.qtd>0);

        const data={
            name:$('#des-name').value.trim(),
            permissao:$('#des-perm').value.trim(),
            precisa_de_item:$('#des-needs-item').checked,
            itens_necessarios,
            inicio:read3('des-start'),
            local_veiculo:read3('des-vehicle'),
            local_ferramentas:read4('des-tools'),
            local_finalizar:read3('des-finish'),
            log_webhook:$('#des-webhook').value.trim()
        };

        if(!data.name)return toast('Informe o identificador.','error');
        if(!data.permissao)return toast('Informe a permissão.','error');

        const allCoords=[
            ...Object.values(data.inicio),
            ...Object.values(data.local_veiculo),
            ...Object.values(data.local_ferramentas),
            ...Object.values(data.local_finalizar)
        ];

        if(allCoords.some(v=>!Number.isFinite(v))){
            return toast('Defina todas as posições no jogo antes de salvar.','error');
        }

        if(!itens_necessarios.length){
            return toast('Mantenha ao menos um item configurado.','error');
        }

        if(d){
            await save('updateDesmanche',{
                originalName:d.name,
                data
            });
        }else{
            await save('createDesmanche',data);
        }
    };
}

function desmancheSettingsForm(){
    const s=desmancheSettings||{};

    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Configurações do Desmanche';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="sectiontitle">
            <div>
                <b>Pagamento</b>
                <span>Multiplicador aplicado sobre o valor do veículo.</span>
            </div>
        </div>

        <div class="grid2">
            <label class="field">
                <span>Veículo comum</span>
                <input id="des-set-common" type="number" min="0" step="0.01" value="${s.porcentagem_veiculocomum??0.35}" required>
            </label>

            <label class="field">
                <span>Veículo VIP / exclusive</span>
                <input id="des-set-vip" type="number" min="0" step="0.01" value="${s.porcentagem_veiculovip??0.50}" required>
            </label>
        </div>

        <div class="hint">
            Ex.: <b>0.35 = 35%</b> do valor do veículo e <b>0.50 = 50%</b>.
        </div>

        <div class="sectiontitle">
            <div>
                <b>Regras</b>
                <span>Comportamentos globais do resource.</span>
            </div>
        </div>

        <label class="checkrow">
            <input id="des-set-own" type="checkbox" ${s.desmanchar_proprio_veiculo?'checked':''}>
            Permitir desmanchar o próprio veículo
        </label>

        <label class="checkrow">
            <input id="des-set-work" type="checkbox" ${s.desmanchar_veiculo_trabalho?'checked':''}>
            Permitir desmanchar veículos de trabalho
        </label>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Salvar configurações</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const data={
            porcentagem_veiculocomum:Number($('#des-set-common').value),
            porcentagem_veiculovip:Number($('#des-set-vip').value),
            desmanchar_proprio_veiculo:$('#des-set-own').checked,
            desmanchar_veiculo_trabalho:$('#des-set-work').checked
        };

        if(
            !Number.isFinite(data.porcentagem_veiculocomum) ||
            !Number.isFinite(data.porcentagem_veiculovip)
        ){
            return toast('Percentuais inválidos.','error');
        }

        await save('saveDesmancheSettings',data);
    };
}

function facForm(){
    $('#drawer-title').textContent='Cadastrar FAC';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="hint">
            Este cadastro cria automaticamente os 6 cargos na vRP e também
            registra a organização no <b>m_orgs_v2</b>.
        </div>

        <div class="grid2">
            <label class="field">
                <span>orgName da FAC</span>
                <input id="fac-orgname" placeholder="Roxos" required>
            </label>

            <div class="field">
                <span>Tipo da organização (orgType)</span>
                <select id="fac-orgtype">
                    <option value="">Selecione...</option>
                    ${ORG_TYPE_OPTIONS.map(v=>`<option value="${esc(v)}">${esc(v)}</option>`).join('')}
                    <option value="__new__">＋ Novo tipo</option>
                </select>

                <input
                    id="fac-orgtype-custom"
                    class="group-custom-type hidden"
                    placeholder="Digite o novo tipo da organização"
                >
            </div>
        </div>

        <div class="sectiontitle">
            <div>
                <b>Meta da organização</b>
                <span>Configuração inicial do Goals do m_orgs_v2.</span>
            </div>
        </div>

        <div class="grid3">
            <label class="field">
                <span>Item da meta</span>
                <input id="fac-goal-item" placeholder="pecadearma" required>
            </label>

            <label class="field">
                <span>Quantidade necessária</span>
                <input id="fac-goal-amount" type="number" min="1" step="1" value="500" required>
            </label>

            <label class="field">
                <span>Recompensa padrão</span>
                <input id="fac-goal-reward" type="number" min="0" step="1" value="300" required>
            </label>
        </div>

        <div class="hint">
            Exemplo: <b>pecadearma × 500</b> para liberar uma recompensa padrão de <b>R$ 300</b>.
            O líder continua podendo alterar a meta posteriormente dentro do painel da FAC.
        </div>

        <div class="fac-preview">
            <small>Cargos que serão criados</small>
            <div id="fac-preview-list"></div>
        </div>

        <div class="hint">
            Todos recebem <b>gtype = org</b>, o mesmo <b>orgName</b> e <b>orgType</b>.
            Cada cargo recebe automaticamente sua permissão <b>perm.nomecargo</b>.
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">Cadastrar FAC completa</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    const orgTypeSelect=$('#fac-orgtype');
    const orgTypeCustom=$('#fac-orgtype-custom');

    orgTypeSelect.onchange=()=>{
        const custom=orgTypeSelect.value==='__new__';
        orgTypeCustom.classList.toggle('hidden',!custom);
        if(custom)setTimeout(()=>orgTypeCustom.focus(),0);
    };

    const ranks=['Recrutador','Novato','Membro','Gerente','SubLider','Lider'];

    const updatePreview=()=>{
        const org=$('#fac-orgname').value.trim()||'Roxos';

        $('#fac-preview-list').innerHTML=ranks.map(rank=>{
            const name=`${rank}${org}`;
            return `<div class="fac-preview-row">
                <b>${esc(name)}</b>
                <span>${esc(groupDefaultPermission(name))}</span>
            </div>`;
        }).join('');
    };

    $('#fac-orgname').addEventListener('input',updatePreview);
    updatePreview();

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const orgName=$('#fac-orgname').value.trim();
        const goalItem=$('#fac-goal-item').value.trim();
        const goalAmount=Number($('#fac-goal-amount').value);
        const defaultReward=Number($('#fac-goal-reward').value);

        if(!orgName)return toast('Informe o orgName da FAC.','error');
        if(!goalItem)return toast('Informe o item da meta.','error');
        if(!Number.isFinite(goalAmount)||goalAmount<=0)return toast('Quantidade da meta inválida.','error');
        if(!Number.isFinite(defaultReward)||defaultReward<0)return toast('Recompensa padrão inválida.','error');

        const orgType=orgTypeSelect.value==='__new__'
            ?orgTypeCustom.value.trim()
            :orgTypeSelect.value.trim();

        if(!orgType)return toast('Selecione o tipo da organização.','error');

        const r=await nui('createFacGroups',{
            orgName,
            orgType,
            goalItem,
            goalAmount,
            defaultReward
        });

        if(!r?.ok)return toast(r?.message||'Não foi possível criar a FAC.','error');

        toast(r.message||'FAC criada com sucesso.');
        closeDrawer();
        await loadAll(true);
    };
}


async function confirmDeleteFac(orgName){
    const r=await nui('deleteFacBundle',{orgName});

    if(!r?.ok){
        toast(r?.message||'Não foi possível excluir a FAC.','error');
        return false;
    }

    toast(r.message||'FAC excluída.');
    closeDrawer();
    await loadAll(true);
    return true;
}

function openFacDeleteConfirm(orgName){
    const modal=$('#confirm');
    if(!modal){
        // Segurança: se o modal padrão não existir, não usa confirm() nativo.
        return toast('Modal de confirmação não encontrado.','error');
    }

    const title=$('#confirm-title');
    const textEl=$('#confirm-text');
    const ok=$('#confirm-ok');
    const cancel=$('#confirm-cancel');

    title.textContent='Excluir FAC completa?';
    textEl.innerHTML=`A FAC <b>${esc(orgName)}</b> será removida por completo.<br><br>
        Isso exclui todos os cargos vinculados e também a organização no m_orgs_v2.`;

    modal.classList.remove('hidden');

    const close=()=>{
        modal.classList.add('hidden');
        ok.onclick=null;
        cancel.onclick=null;
    };

    cancel.onclick=close;

    ok.onclick=async()=>{
        ok.disabled=true;
        const oldText=ok.textContent;
        ok.textContent='Excluindo...';

        const success=await confirmDeleteFac(orgName);

        ok.disabled=false;
        ok.textContent=oldText;

        if(success){
            close();
        }
    };
}

function deleteFacForm(){
    const facs=getFacNames();

    if(!facs.length){
        return toast('Nenhuma FAC do tipo org foi encontrada.','error');
    }

    $('#drawer').classList.add('open');
    $('#overlay').classList.remove('hidden');
    $('#drawer-title').textContent='Excluir FAC';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="hint danger-hint">
            Esta ação exclui <b>todos os cargos</b> vinculados ao orgName na vRP
            e remove a organização do <b>m_orgs_v2</b>.
        </div>

        <label class="field">
            <span>FAC / orgName</span>
            <select id="fac-delete-name" required>
                <option value="">Selecione...</option>
                ${facs.map(name=>`<option value="${esc(name)}">${esc(name)}</option>`).join('')}
            </select>
        </label>

        <div id="fac-delete-preview" class="fac-preview">
            <small>Cargos que serão removidos</small>
            <div class="muted">Selecione uma FAC.</div>
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn dangerbtn">Excluir FAC completa</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;

    const select=$('#fac-delete-name');
    select.onchange=()=>{
        const org=select.value;
        const groups=managedGroups
            .filter(g=>String(g.config?.gtype||'')==='org' && String(g.config?.orgName||'')===org)
            .map(g=>g.name)
            .sort((a,b)=>a.localeCompare(b,undefined,{sensitivity:'base'}));

        $('#fac-delete-preview').innerHTML=`
            <small>Cargos que serão removidos</small>
            ${groups.length
                ?groups.map(name=>`<div class="fac-preview-row"><b>${esc(name)}</b><span>excluir</span></div>`).join('')
                :'<div class="muted">Nenhum cargo encontrado.</div>'
            }
        `;
    };

    $('#form').onsubmit=async e=>{
        e.preventDefault();
        const orgName=select.value;

        if(!orgName)return toast('Selecione a FAC.','error');

        openFacDeleteConfirm(orgName);
    };
}

function groupForm(g){
    const isNew=!g;
    const cfg=g?.config||{};
    const initialDefault=isNew?groupDefaultPermission(''):'';

    const currentGroupType=String(cfg.gtype||'');
    const isCustomGroupType=!!currentGroupType&&!GROUP_TYPE_OPTIONS.includes(currentGroupType);

    const currentOrgType=String(cfg.orgType||'');
    const isCustomOrgType=!!currentOrgType&&!ORG_TYPE_OPTIONS.includes(currentOrgType);

    $('#drawer-title').textContent=g?`Editar ${g.name}`:'Cadastrar cargo';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <label class="field">
            <span>Nome / Identificador do cargo</span>
            <input id="grp-name" value="${esc(g?.name||'')}" placeholder="Lenhador" required>
        </label>

        ${g?`<div class="hint">Você pode renomear o cargo. Os usuários que possuem <b>${esc(g.name)}</b> serão migrados automaticamente para o novo nome. Referências escritas manualmente em outros scripts não são renomeadas.</div>`:''}

        <div class="grid2">
            <div class="field">
                <span>Tipo (gtype)</span>
                <select id="grp-type">
                    <option value="" ${!currentGroupType?'selected':''}>Não definido</option>
                    ${GROUP_TYPE_OPTIONS.map(v=>groupSelectOption(v,isCustomGroupType?'':currentGroupType)).join('')}
                    <option value="__new__" ${isCustomGroupType?'selected':''}>＋ Novo tipo</option>
                </select>
                <input
                    id="grp-type-custom"
                    class="group-custom-type ${isCustomGroupType?'':'hidden'}"
                    value="${esc(isCustomGroupType?currentGroupType:'')}"
                    placeholder="Digite o novo tipo"
                >
            </div>

            <label class="field">
                <span>Salário</span>
                <input id="grp-salary" type="number" min="0" step="1" value="${cfg.salario??''}" placeholder="Deixe vazio para nil">
            </label>
        </div>

        <div class="grid2">
            <label class="field">
                <span>PTR</span>
                <select id="grp-ptr">
                    <option value="" ${cfg.ptr==null?'selected':''}>Não definido (nil)</option>
                    <option value="true" ${cfg.ptr===true?'selected':''}>true</option>
                    <option value="false" ${cfg.ptr===false?'selected':''}>false</option>
                </select>
            </label>

            <label class="field">
                <span>Título opcional</span>
                <input id="grp-title" value="${esc(cfg.title||'')}" placeholder="Nome amigável opcional">
            </label>
        </div>

        <div class="grid2">
            <label class="field">
                <span>Organização (orgName)</span>
                <input id="grp-orgname" value="${esc(cfg.orgName||'')}" placeholder="Policia, Lenhador...">
            </label>

            <div class="field">
                <span>Tipo da organização (orgType)</span>
                <select id="grp-orgtype">
                    <option value="" ${!currentOrgType?'selected':''}>Não definido</option>
                    ${ORG_TYPE_OPTIONS.map(v=>groupSelectOption(v,isCustomOrgType?'':currentOrgType)).join('')}
                    <option value="__new__" ${isCustomOrgType?'selected':''}>＋ Novo tipo</option>
                </select>
                <input
                    id="grp-orgtype-custom"
                    class="group-custom-type ${isCustomOrgType?'':'hidden'}"
                    value="${esc(isCustomOrgType?currentOrgType:'')}"
                    placeholder="Digite o novo tipo da organização"
                >
            </div>
        </div>

        <div class="sectiontitle">
            <div>
                <b>Permissões</b>
                <span>Adicione ou remova permissões livremente.</span>
            </div>
            <button type="button" id="grp-add-perm" class="btn ghost mini">＋ Adicionar permissão</button>
        </div>

        <div id="group-permissions">${
            isNew
                ? groupPermissionRow(initialDefault,true)
                : (g.permissions||[]).map(p=>groupPermissionRow(p,false)).join('')
        }</div>

        <div class="hint">
            Ao criar um cargo, a primeira permissão é gerada automaticamente a partir do nome:
            <b>Lenhador → perm.lenhador</b>, <b>NovatoBombeiro → perm.novatobombeiro</b>.
        </div>

        <div class="formactions">
            <button type="button" class="btn ghost cancel">Cancelar</button>
            <button class="btn primary">${g?'Salvar cargo':'Criar cargo'}</button>
        </div>
    </form>`;

    $('.cancel').onclick=closeDrawer;
    bindGroupPermissionRows();

    const bindCustomTypeSelect=(selectId,inputId)=>{
        const select=$(selectId);
        const input=$(inputId);

        const sync=()=>{
            const custom=select.value==='__new__';
            input.classList.toggle('hidden',!custom);

            if(custom){
                setTimeout(()=>input.focus(),0);
            }
        };

        select.addEventListener('change',sync);
        sync();
    };

    bindCustomTypeSelect('#grp-type','#grp-type-custom');
    bindCustomTypeSelect('#grp-orgtype','#grp-orgtype-custom');

    $('#grp-add-perm').onclick=()=>{
        $('#group-permissions').insertAdjacentHTML('beforeend',groupPermissionRow('',false));
        bindGroupPermissionRows();
        const input=$('#group-permissions').lastElementChild.querySelector('.gp-value');
        input.focus();
    };

    if(isNew){
        $('#grp-name').addEventListener('input',()=>{
            const autoRow=$('#group-permissions .group-permission-row[data-auto="1"]');
            if(!autoRow)return;
            autoRow.querySelector('.gp-value').value=groupDefaultPermission($('#grp-name').value);
        });
    }

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const name=$('#grp-name').value.trim();
        if(!name)return toast('Informe o nome do cargo.','error');

        const permissions=[];
        const seen=new Set();

        $$('#group-permissions .gp-value').forEach(input=>{
            const value=input.value.trim();
            if(value&&!seen.has(value)){
                seen.add(value);
                permissions.push(value);
            }
        });

        const ptrValue=$('#grp-ptr').value;
        const salaryRaw=$('#grp-salary').value.trim();

        const group={
            name,
            config:{
                gtype:$('#grp-type').value==='__new__'
                    ? $('#grp-type-custom').value.trim()
                    : $('#grp-type').value.trim(),
                salario:salaryRaw===''?'':Number(salaryRaw),
                ptr:ptrValue===''?'':ptrValue==='true',
                title:$('#grp-title').value.trim(),
                orgName:$('#grp-orgname').value.trim(),
                orgType:$('#grp-orgtype').value==='__new__'
                    ? $('#grp-orgtype-custom').value.trim()
                    : $('#grp-orgtype').value.trim()
            },
            permissions
        };

        await save('saveManagedGroup',{
            originalName:g?.name||'',
            group
        });
    };
}

function mapMarkingForm(x){
    $('#drawer-title').textContent=
        x ? `Editar ${x.name}` : 'Nova Marcação Mapa';

    $('#drawer-body').innerHTML=`<form id="form" class="form">
        <div class="mapblippreview">
            <div id="mm-icon-preview">${mapBlipIcon(x?.sprite??1,'mapblipicon large')}</div>
            <div>
                <span>Prévia do ícone</span>
                <b id="mm-preview-name">${esc(x?.name||'Nova marcação')}</b>
                <small>Sprite <strong id="mm-preview-sprite">${esc(x?.sprite??1)}</strong></small>
            </div>
        </div>

        <label class="field">
            <span>Nome exibido no mapa</span>
            <input
                id="mm-name"
                value="${esc(x?.name||'')}"
                placeholder="Hospital"
                required
            >
        </label>

        <div class="grid3 map-config-grid">
            <div class="field">
                <span>Sprite / Blip ID</span>
                <div class="picker-field-row">
                    <input
                        id="mm-sprite"
                        type="number"
                        min="0"
                        step="1"
                        value="${x?.sprite??1}"
                        required
                    >
                    <button type="button" id="mm-choose-sprite" class="btn ghost mini">
                        Escolher sprite
                    </button>
                </div>
            </div>

            <div class="field">
                <span>Cor</span>
                <div class="picker-field-row">
                    <input
                        id="mm-color"
                        type="number"
                        min="0"
                        max="80"
                        step="1"
                        value="${x?.color??0}"
                        required
                    >
                    <button type="button" id="mm-choose-color" class="btn ghost mini">
                        Escolher cor
                    </button>
                </div>
                <div class="chosen-color-preview">
                    <span id="mm-color-preview"></span>
                    <small id="mm-color-label"></small>
                </div>
            </div>

            <label class="field">
                <span>Escala</span>
                <input
                    id="mm-scale"
                    type="number"
                    min="0.05"
                    step="0.05"
                    value="${x?.scale??0.5}"
                    required
                >
            </label>
        </div>

        ${coordsBlock('mm',x?.coords)}

        <div class="hint">
            Sprite define o ícone do GTA/FiveM, Cor define a cor
            e Escala controla o tamanho da marcação.
        </div>

        <div class="formactions">
            <button
                type="button"
                class="btn ghost cancel"
            >
                Cancelar
            </button>

            ${x?`
                <button
                    type="button"
                    id="mm-tp"
                    class="btn ghost"
                >
                    ⌖ Teleportar
                </button>
            `:''}

            <button class="btn primary">
                ${x?'Salvar alterações':'Cadastrar marcação'}
            </button>
        </div>
    </form>`;

    bindPosition('mm');
    $('.cancel').onclick=closeDrawer;

    if(x){
        $('#mm-tp').onclick=async()=>{
            const r=await nui(
                'teleport',
                {coords:x.coords}
            );

            if(!r?.ok){
                toast(
                    r?.message||
                    'Não foi possível teleportar.',
                    'error'
                );
            }
        };
    }

    $('#mm-choose-sprite').onclick=openSpritePicker;
    $('#mm-choose-color').onclick=openColorPicker;
    $('#mm-color').addEventListener('input',updateMapColorPreview);
    updateMapColorPreview();

    const updateMapPreview=()=>{
        const sprite=Number($('#mm-sprite').value)||0;
        const name=$('#mm-name').value.trim()||'Nova marcação';

        $('#mm-icon-preview').innerHTML=mapBlipIcon(sprite,'mapblipicon large');

        if(!mapBlipFile(sprite)){
            loadMapBlipCatalog().then(()=>{
                if($('#mm-icon-preview') && Number($('#mm-sprite')?.value)===sprite){
                    $('#mm-icon-preview').innerHTML=mapBlipIcon(sprite,'mapblipicon large');
                }
            });
        }
        $('#mm-preview-name').textContent=name;
        $('#mm-preview-sprite').textContent=String(sprite);
    };

    $('#mm-sprite').addEventListener('input',updateMapPreview);
    $('#mm-name').addEventListener('input',updateMapPreview);

    $('#form').onsubmit=async e=>{
        e.preventDefault();

        const payload={
            id:x?.id,
            name:$('#mm-name').value.trim(),
            sprite:+$('#mm-sprite').value,
            color:+$('#mm-color').value,
            scale:+$('#mm-scale').value,
            shortRange:true,
            coords:{
                x:+$('#mm-x').value,
                y:+$('#mm-y').value,
                z:+$('#mm-z').value
            }
        };

        if(!payload.name){
            return toast(
                'Informe o nome da marcação.',
                'error'
            );
        }

        if(
            !Number.isFinite(payload.coords.x) ||
            !Number.isFinite(payload.coords.y) ||
            !Number.isFinite(payload.coords.z)
        ){
            return toast(
                'Coordenadas inválidas.',
                'error'
            );
        }

        await save(
            x?'updateMapMarking':'createMapMarking',
            payload
        );
    };
}


async function save(event,data){
    const r=await nui(event,data);
    if(!r.ok)return toast(r.message||'Falha ao salvar.','error');
    toast(r.message||'Salvo com sucesso.');
    closeDrawer();
    await loadAll(true);
}

function askDelete(kind,id){
    pending={kind,id};

    const label={
        chest:'Excluir este baú?',
        garage:'Excluir esta garagem?',
        type:'Excluir este tipo?',
        shop:'Excluir esta loja?',
        craft:'Excluir esta bancada e o farm vinculado?',
        clothing:'Excluir este local da loja de roupa?',
        barbershop:'Excluir este local da barbearia?',
        tattoo:'Excluir este local do Estúdio Tattoo?',
        cloakroom:'Excluir este Blip Fardamento e todos os fardamentos dele?',
        mapmarking:'Excluir esta marcação do mapa?',
        group:'Excluir este cargo?',
        desmanche:'Excluir este desmanche?',
        safezone:'Excluir esta SafeZone?',
        residence:'Excluir esta residência?',
        mansion:'Excluir esta mansão?',
        dealershipvehicle:'Remover este veículo da concessionária?',
        servervehicle:'Excluir este veículo do servidor?'
    }[kind];

    $('#confirm-title').textContent=label||'Excluir cadastro?';
    $('#confirm-text').innerHTML=kind==='group'
        ?`O cargo <b>${esc(id)}</b> será removido do groups.json e também retirado dos usuários que o possuem.`
        :kind==='servervehicle'
            ?`O veículo <b>${esc(serverVehicleCatalog?.[id]?.name||id)}</b> (<b>${esc(id)}</b>) será removido do catálogo do servidor e do <b>shared-side/listcars.json</b>.`
            :`O cadastro <b>${esc(id)}</b> será removido do JSON e a alteração será sincronizada imediatamente.`;
    $('#confirm').classList.remove('hidden');
}

$$('.nav[data-module]').forEach(b=>b.onclick=()=>setModule(b.dataset.module));
$$('.tab').forEach(b=>b.onclick=()=>{
    garageTab=b.dataset.tab;
    $$('.tab').forEach(x=>x.classList.toggle('active',x===b));
    updateModuleFilters(true);
    render();
});

$('#search').oninput=render;
$('#sort').onchange=render;
$('#group-filter').onchange=render;
updateModuleFilters(true);
$('#refresh').onclick=()=>loadAll();
$('#new').onclick=()=>{
    if([].includes(module)){
        return toast('Módulo preparado. Envie o resource correspondente para habilitarmos os cadastros.','error');
    }
    openDrawer(currentKind());
};
$('#close').onclick=()=>{$('#app').classList.add('hidden');nui('close')};
$('#drawer-close').onclick=closeDrawer;
$('#overlay').onclick=closeDrawer;

$('#tbody').onclick=async e=>{
    const b=e.target.closest('[data-a]');
    if(!b)return;

    const a=b.dataset.a;
    const k=b.dataset.k;
    const id=dec(b.dataset.id);

    if(a==='del')return askDelete(k,id);

    if(a==='edit'){
        if(k==='chest')openDrawer(k,chests.find(x=>x.name===id));
        if(k==='garage')openDrawer(k,garages.find(x=>String(x.id)===id));
        if(k==='type')openDrawer(k,garageTypes.find(x=>x.name===id));
        if(k==='shop')openDrawer(k,shops.find(x=>x.name===id));
        if(k==='craft')openDrawer(k,(craftSetups.benches||[]).find(x=>x.name===id));
        if(k==='clothing')openDrawer(k,clothingShops.find(x=>String(x.id)===id));
        if(k==='barbershop')openDrawer(k,barbershops.find(x=>String(x.id)===id));
        if(k==='tattoo')openDrawer(k,tattooShops.find(x=>String(x.id)===id));
        if(k==='cloakroom')openDrawer(k,cloakrooms.find(x=>String(x.name)===id));
        if(k==='mapmarking')openDrawer(k,mapMarkings.find(x=>String(x.id)===id));
        if(k==='group')openDrawer(k,managedGroups.find(x=>String(x.name)===id));
        if(k==='desmanche')openDrawer(k,desmanches.find(x=>String(x.name)===id));
        if(k==='safezone')openDrawer(k,safeZones.find(x=>String(x.name)===id));
        if(k==='job'){const d=jobsData.jobs?.[id];if(d)openDrawer(k,{name:id,data:d,extra:jobsData.extras?.[id]||{}});}
        if(k==='residence')openDrawer(k,(residencesData.residences||[]).find(x=>String(x.name)===id));
        if(k==='mansion')openDrawer(k,(mansionsData.mansions||[]).find(x=>String(x.id)===id));
        if(k==='dealershipvehicle'){
            const state=dealershipData.vehicles?.[id];
            const meta=dealershipData.runtimeVehicles?.[id]||serverVehicleCatalog?.[id]||{};
            if(state)openDrawer(k,{spawn:id,...meta,...state});
        }
        return;
    }

    if(a==='tp'){
        let coords=null;
        if(k==='chest')coords=chests.find(x=>x.name===id)?.coords;
        if(k==='garage')coords=garages.find(x=>String(x.id)===id)?.coords;
        if(k==='shop')coords=shops.find(x=>x.name===id)?.data?.coords?.[0]?.coords;
        if(k==='craft')coords=(craftSetups.benches||[]).find(x=>x.name===id)?.coords?.[0];
        if(k==='clothing')coords=clothingShops.find(x=>String(x.id)===id)?.coords;
        if(k==='barbershop')coords=barbershops.find(x=>String(x.id)===id)?.coords;
        if(k==='tattoo')coords=tattooShops.find(x=>String(x.id)===id)?.coords;
        if(k==='cloakroom')coords=cloakrooms.find(x=>String(x.name)===id)?.coords;
        if(k==='mapmarking')coords=mapMarkings.find(x=>String(x.id)===id)?.coords;
        if(k==='desmanche')coords=desmanches.find(x=>String(x.name)===id)?.inicio;
        if(k==='job'){const p=jobsData.jobs?.[id]?.inicio;if(p)coords={x:Number(p[0]),y:Number(p[1]),z:Number(p[2])};}
        if(k==='residence'){const h=(residencesData.residences||[]).find(x=>String(x.name)===id);if(h)coords={x:Number(h.x),y:Number(h.y),z:Number(h.z)};}
        if(k==='mansion')coords=(mansionsData.mansions||[]).find(x=>String(x.id)===id)?.purchaseCoords;
        if(k==='safezone'){
            const z=safeZones.find(x=>String(x.name)===id);
            const p=z?.zones?.[0];
            if(p?.coords?.length){
                const avg=p.coords.reduce((a,c)=>({x:a.x+Number(c.x||0),y:a.y+Number(c.y||0)}),{x:0,y:0});
                coords={
                    x:avg.x/p.coords.length,
                    y:avg.y/p.coords.length,
                    z:(Number(p.minZ||0)+Number(p.maxZ||0))/2
                };
            }
        }

        if(coords)await nui('teleport',{coords});
    }
};

$('#confirm-cancel').onclick=()=>{
    $('#confirm').classList.add('hidden');
    pending=null;
};

$('#confirm-ok').onclick=async()=>{
    if(!pending)return;

    const deleting={...pending};
    const okBtn=$('#confirm-ok');
    const cancelBtn=$('#confirm-cancel');

    let ev,data;
    if(deleting.kind==='chest'){ev='deleteChest';data={name:deleting.id}}
    if(deleting.kind==='garage'){ev='deleteGarage';data={id:deleting.id}}
    if(deleting.kind==='type'){ev='deleteGarageType';data={name:deleting.id}}
    if(deleting.kind==='shop'){ev='deleteShop';data={name:deleting.id}}
    if(deleting.kind==='craft'){ev='deleteCraftSetup';data={name:deleting.id}}
    if(deleting.kind==='clothing'){ev='deleteClothingShop';data={id:deleting.id}}
    if(deleting.kind==='barbershop'){ev='deleteBarbershop';data={id:deleting.id}}
    if(deleting.kind==='tattoo'){ev='deleteTattooShop';data={id:deleting.id}}
    if(deleting.kind==='cloakroom'){ev='deleteCloakroom';data={name:deleting.id}}
    if(deleting.kind==='mapmarking'){ev='deleteMapMarking';data={id:deleting.id}}
    if(deleting.kind==='group'){ev='deleteManagedGroup';data={name:deleting.id}}
    if(deleting.kind==='desmanche'){ev='deleteDesmanche';data={name:deleting.id}}
    if(deleting.kind==='safezone'){ev='deleteSafeZone';data={name:deleting.id}}
    if(deleting.kind==='residence'){ev='deleteResidence';data={name:deleting.id}}
    if(deleting.kind==='mansion'){ev='deleteMansion';data={id:deleting.id}}
    if(deleting.kind==='dealershipvehicle'){ev='deleteDealershipVehicle';data={spawn:deleting.id}}
    if(deleting.kind==='servervehicle'){ev='deleteServerVehicle';data={spawn:deleting.id}}

    if(!ev)return toast('Ação de exclusão inválida.','error');

    okBtn.disabled=true;
    cancelBtn.disabled=true;
    const oldText=okBtn.textContent;
    okBtn.textContent='Excluindo...';

    const r=await nui(ev,data);

    okBtn.disabled=false;
    cancelBtn.disabled=false;
    okBtn.textContent=oldText;

    if(!r?.ok)return toast(r?.message||'Falha ao excluir.','error');

    toast(r.message||'Excluído.');
    $('#confirm').classList.add('hidden');
    pending=null;

    // Catálogo do servidor pode conter mais de 1.000 veículos.
    // Não recarregamos o Config Manager inteiro após excluir apenas um deles:
    // atualizamos somente os estados locais afetados.
    if(deleting.kind==='servervehicle'){
        if(serverVehicleCatalog && serverVehicleCatalog[deleting.id]){
            delete serverVehicleCatalog[deleting.id];
        }

        if(dealershipData?.runtimeVehicles?.[deleting.id]){
            delete dealershipData.runtimeVehicles[deleting.id];
        }

        dealershipView='server';
        updateModuleFilters(false);
        render();
        syncGroupTopActions();
        return;
    }

    // Mesma otimização para remover um veículo apenas do estoque da concessionária.
    if(deleting.kind==='dealershipvehicle'){
        if(dealershipData?.vehicles?.[deleting.id]){
            delete dealershipData.vehicles[deleting.id];
        }
        if(dealershipData?.runtimeVehicles?.[deleting.id]){
            delete dealershipData.runtimeVehicles[deleting.id];
        }

        dealershipView='dealership';
        updateModuleFilters(false);
        render();
        syncGroupTopActions();
        return;
    }

    await loadAll(true);
};

window.addEventListener('message',e=>{
    const d=e.data||{};

    if(d.action==='open'){
        $('#app').classList.remove('hidden');
        serverItems=[];
        loadAll(true);
    }

    if(d.action==='close')$('#app').classList.add('hidden');

    if(d.action==='mansionPositionCaptured'){
        applyMansionCapturedPosition(String(d.target||''),d.coords||{});
    }

    if(d.action==='mansionPositionCancelled'){
        toast('Posicionamento da mansão cancelado.','error');
    }

    if(d.action==='mansionDoorsCaptured'){
        mansionDoorDraft=Array.isArray(d.doors)?d.doors:[];
        updateMansionDoorStatus();
        toast(`${mansionDoorDraft.length} tranca(s) configurada(s).`);
    }

    if(d.action==='mansionDoorCaptureCancelled'){
        toast(d.message||'Captura de trancas cancelada.','error');
    }

    if(d.action==='spawnPositionCaptured'){
        const box=$('#spawns');
        if(box&&d.coords){
            box.insertAdjacentHTML('beforeend',spawnRow(d.coords));
            const row=box.lastElementChild;
            row.querySelector('.remove').onclick=()=>row.remove();
            toast('Posição de saída adicionada.');
        }
    }

    if(d.action==='spawnPositionCancelled')toast('Posicionamento cancelado.','error');

    if(d.action==='shopPositionCaptured'){
        const box=$('#shop-points');
        if(box&&d.coords){
            box.insertAdjacentHTML('beforeend',shopPointRow({coords:d.coords,blip:false}));
            const row=box.lastElementChild;
            row.querySelector('.remove').onclick=()=>row.remove();
            row.querySelector('.pointtp').onclick=async()=>{
                const coords={
                    x:Number(row.querySelector('.px').value),
                    y:Number(row.querySelector('.py').value),
                    z:Number(row.querySelector('.pz').value)
                };
                if(!Number.isFinite(coords.x)||!Number.isFinite(coords.y)||!Number.isFinite(coords.z))
                    return toast('Coordenadas inválidas neste ponto.','error');
                const r=await nui('teleport',{coords});
                if(!r?.ok)toast(r?.message||'Não foi possível teleportar.','error');
            };
            toast('Ponto da loja adicionado.');
        }
    }

    if(d.action==='desmanchePositionCaptured'){
        const prefix=String(d.target||'');
        const c=d.coords||{};

        if(prefix && $(`#${prefix}-x`)){
            $(`#${prefix}-x`).value=c.x;
            $(`#${prefix}-y`).value=c.y;
            $(`#${prefix}-z`).value=c.z;

            const w=$(`#${prefix}-w`);
            if(w && c.w!=null)w.value=c.w;

            toast('Posição do desmanche capturada.');
        }
    }

    if(d.action==='desmanchePositionCancelled'){
        toast('Posicionamento cancelado.','error');
    }

    if(d.action==='safeZonePolygonCaptured'){
        const cards=$$('#safe-polygons .safe-poly-card');
        const card=cards[Number(d.target)||0];

        if(card){
            const coords=d.coords||[];
            card.querySelector('.safe-coords-json').value=JSON.stringify(coords);
            card.querySelector('.safe-point-count').textContent=String(coords.length);

            if(!card.querySelector('.safe-minz').value && d.minCapturedZ!=null){
                card.querySelector('.safe-minz').value=(Number(d.minCapturedZ)-2).toFixed(2);
            }
            if(!card.querySelector('.safe-maxz').value && d.maxCapturedZ!=null){
                card.querySelector('.safe-maxz').value=(Number(d.maxCapturedZ)+15).toFixed(2);
            }

            card.querySelector('.safe-poly-summary').innerHTML=coords.length
                ?`<span>Primeiro ponto: <b>${f(coords[0]?.x)}, ${f(coords[0]?.y)}</b></span>
                  <span>Último ponto: <b>${f(coords[coords.length-1]?.x)}, ${f(coords[coords.length-1]?.y)}</b></span>`
                :'<span class="muted">Nenhum ponto.</span>';

            card.querySelector('.safe-draw-poly').textContent='⌖ Redesenhar no jogo';
            toast(`Polígono capturado com ${coords.length} pontos.`);
        }
    }

    if(d.action==='safeZonePolygonCancelled'){
        toast('Desenho da SafeZone cancelado.','error');
    }

    if(d.action==='shopPositionCancelled')toast('Posicionamento cancelado.','error');
});

$('#item-picker-close').onclick=()=>{closeItemPicker();restoreShopPickerHeader();};
$('#item-picker-cancel').onclick=()=>{closeItemPicker();restoreShopPickerHeader();};
$('#item-picker-search').oninput=renderItemPicker;
$('#item-picker-toggle').onclick=()=>{
    const q=$('#item-picker-search').value.trim().toLowerCase();
    const visible=serverItems.filter(i=>!q||i.name.toLowerCase().includes(q)||i.index.toLowerCase().includes(q));
    const allSelected=visible.length&&visible.every(i=>pickerSelection.has(i.index));
    visible.forEach(i=>allSelected?pickerSelection.delete(i.index):pickerSelection.add(i.index));
    renderItemPicker();
};
$('#item-picker-add').onclick=()=>{
    if(pickerContext?.type==='craft-product'){
        const index=[...pickerSelection][0];
        if(!index)return toast('Selecione um item para a receita.','error');
        const box=pickerContext.box;
        closeItemPicker();
        renderRecipeProduct(box,index);
        restoreShopPickerHeader();
        toast(`${itemName(index)} definido como item produzido.`);
        return;
    }

    if(pickerContext?.type==='craft-materials'){
        const box=pickerContext.box;
        const oldAmounts={};
        box.querySelectorAll('.craftmaterialrow').forEach(r=>oldAmounts[r.dataset.index]=Number(r.querySelector('.materialamount').value)||1);
        const materials=box.querySelector('.craftmaterials');
        materials.innerHTML=[...pickerSelection].map(index=>craftMaterialRow({name:index,amount:oldAmounts[index]??1})).join('');
        bindCraftMaterialActions(box);
        closeItemPicker();
        const count=pickerSelection.size;
        restoreShopPickerHeader();
        toast(`${count} ${count===1?'material selecionado':'materiais selecionados'} para a receita.`);
        return;
    }

    const old={...shopItemDraft};
    shopItemDraft={};
    pickerSelection.forEach(index=>shopItemDraft[index]=old[index]??0);
    closeItemPicker();
    renderShopItems();
    toast(`${pickerSelection.size} ${pickerSelection.size===1?'item adicionado':'itens adicionados'} à loja.`);
};

document.addEventListener('keyup',e=>{
    if(e.key!=='Escape')return;

    if(!$('#item-picker').classList.contains('hidden')){
        closeItemPicker();
    }else if(!$('#confirm').classList.contains('hidden')){
        $('#confirm').classList.add('hidden');
    }else if($('#drawer').classList.contains('open')){
        closeDrawer();
    }else{
        $('#app').classList.add('hidden');
        nui('close');
    }
});

document.addEventListener('click',e=>{
    const b=e.target.closest('[data-a="rob-open"]');
    if(b) robberyHubForm();
    const bank=e.target.closest('[data-a="bank-open"]');
    if(bank) bancoCentralForm();
    const jewelry=e.target.closest('[data-a="jewelry-open"]');
    if(jewelry) joalheriaForm();
    const vault=e.target.closest('[data-a="vault-open"]');
    if(vault) roubocofreForm();
});


document.addEventListener('click',e=>{
    const edit=e.target.closest('[data-server-edit]');
    if(edit){
        const spawn=dec(edit.dataset.serverEdit);
        const data=serverVehicleCatalog?.[spawn];
        if(data)serverVehicleForm({spawn,...data});
        return;
    }

    const del=e.target.closest('[data-server-delete]');
    if(del){
        const spawn=dec(del.dataset.serverDelete);
        askDelete('servervehicle',spawn);
    }
});


document.addEventListener('change',e=>{
    const one=e.target.closest('[data-server-select]');
    if(one){
        const spawn=dec(one.dataset.serverSelect);
        if(one.checked)serverVehicleBulkSelection.add(spawn);
        else serverVehicleBulkSelection.delete(spawn);

        const row=one.closest('tr');
        if(row)row.classList.toggle('bulk-selected',one.checked);
        refreshServerBulkControls();
        syncGroupTopActions();
        return;
    }

    if(e.target.id==='server-bulk-check-visible'){
        const checked=e.target.checked;
        (serverVehicleVisibleSpawns||[]).forEach(spawn=>{
            if(checked)serverVehicleBulkSelection.add(spawn);
            else serverVehicleBulkSelection.delete(spawn);
        });
        render();
        syncGroupTopActions();
    }
});
