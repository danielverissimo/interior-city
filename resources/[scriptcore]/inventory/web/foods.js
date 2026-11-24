const interiorFoodImages = new Set(["pamonha","curau","tapioca","cuscuz","bolodemilho","galinhada","arrozcompequi","feijaotropeiro","arrozcarreteiro","docedeleite","goiabada","pacoca","pedemoleque","caldodecana","cafecoado"]);
window.inventoryItemImage = (id) => {
    if (interiorFoodImages.has(id)) return `./images/foods/${id}.png`;
    return window.htdocsItemImage(id) || `http://127.0.0.1/images/${encodeURIComponent(id ?? '')}.png`;
};
