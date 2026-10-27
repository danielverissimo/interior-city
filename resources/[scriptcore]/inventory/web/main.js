window.classInstances = {};
globalThis.SelectedItem = {};
window.imageUrl = 'http://127.0.0.1/images/'

window.isOnline = true;

window.addEventListener("online", () => {
	window.isOnline = true;
	$("#inventory").removeClass("offline");
});

window.addEventListener("offline", () => {
	window.isOnline = false;
	$("#inventory").addClass("offline");
});


let quickHotbarTimer = null;
let quickHotbarHideTimer = null;
let quickHotbarHeld = false;

let weaponHudHideTimer = null;
let equippedWeaponsRefreshTimer = null;
let equippedWeaponsRefreshToken = 0;

function getSnapshotSlot(slots, index) {
	if (!slots) return null;
	return slots[index - 1] || slots[index] || slots[String(index)] || null;
}

function renderEquippedWeaponsPanel(snapshot = {}) {
	const root = document.querySelector("#equipped-weapons-panel");
	const list = document.querySelector("#equipped-weapons-list");
	const count = document.querySelector("#equipped-weapons-count");
	if (!root || !list || !count) return;

	const activeSlot = Number(snapshot.active_slot || 0);
	const weapons = [];
	for (let i = 1; i <= 5; i++) {
		const slot = getSnapshotSlot(snapshot.slots, i);
		if (!slot || slot.empty || slot.type !== "equip") continue;
		weapons.push({ ...slot, slot: Number(slot.slot || i), active: activeSlot === i || slot.equipped === true });
	}

	count.textContent = String(weapons.length);
	list.innerHTML = "";

	if (!weapons.length) {
		list.innerHTML = `
			<div class="equipped-weapons-empty">
				<div class="equipped-weapons-empty-icon">—</div>
				<strong>Nenhuma arma equipada</strong>
				<span>Coloque uma arma nos slots 1 a 5.</span>
			</div>
		`;
		return;
	}

	for (const weapon of weapons) {
		const ammo = weapon.ammo || {};
		const clip = Math.max(0, Number(ammo.clip) || 0);
		const reserve = Math.max(0, Number(ammo.reserve) || 0);
		const image = weapon.png || weapon.item || "";
		const displayName = weapon.name || weapon.item || "Arma";
		const weaponKey = weapon.weapon || String(weapon.item || "").toUpperCase();

		const card = document.createElement("div");
		card.className = `equipped-weapon-card${weapon.active ? " is-active" : ""}`;
		card.dataset.slot = String(weapon.slot);
		card.dataset.weapon = weaponKey;
		card.innerHTML = `
			<div class="equipped-weapon-topline">
				<span class="equipped-weapon-slot">SLOT ${weapon.slot}</span>
				${weapon.active ? '<span class="equipped-weapon-state">EM MÃOS</span>' : '<span class="equipped-weapon-state is-stored">PRONTA</span>'}
			</div>
			<div class="equipped-weapon-content">
				<div class="equipped-weapon-visual">
					${image ? `<img src="${window.imageUrl}${image}.png" alt="" onerror="this.onerror=null;this.src='./images/weapon.svg'">` : '<img src="./images/weapon.svg" alt="">'}
				</div>
				<div class="equipped-weapon-info">
					<strong title="${displayName.replace(/"/g, "&quot;")}">${displayName}</strong>
					<div class="equipped-weapon-ammo">
						<span class="equipped-weapon-clip">${clip}</span>
						<span class="equipped-weapon-slash">/</span>
						<span class="equipped-weapon-reserve">${reserve}</span>
					</div>
					<div class="equipped-weapon-ammo-labels"><span>PENTE</span><span>RESERVA</span></div>
				</div>
			</div>
		`;
		list.appendChild(card);
	}
}

async function refreshEquippedWeaponsPanel(snapshot = null) {
	if (!$("#inventory").is(":visible") || !$("#inventory").hasClass("single-inventory")) return;
	const token = ++equippedWeaponsRefreshToken;
	const data = snapshot || await Client("GET_HOTBAR_SNAPSHOT");
	if (token !== equippedWeaponsRefreshToken) return;
	renderEquippedWeaponsPanel(data || { slots: {} });
}

function scheduleEquippedWeaponsPanelRefresh(delay = 80) {
	clearTimeout(equippedWeaponsRefreshTimer);
	equippedWeaponsRefreshTimer = setTimeout(() => refreshEquippedWeaponsPanel(), delay);
}

function updateEquippedWeaponAmmoFromHud(payload = {}) {
	if (!$("#inventory").is(":visible") || !$("#inventory").hasClass("single-inventory")) return;
	const weapon = String(payload.weapon || "");
	if (!weapon) return;

	const cards = document.querySelectorAll(".equipped-weapon-card");
	for (const card of cards) {
		const isActive = card.dataset.weapon === weapon;
		card.classList.toggle("is-active", isActive);
		const state = card.querySelector(".equipped-weapon-state");
		if (state) {
			state.textContent = isActive ? "EM MÃOS" : "PRONTA";
			state.classList.toggle("is-stored", !isActive);
		}
		if (!isActive) continue;
		const clip = card.querySelector(".equipped-weapon-clip");
		const reserve = card.querySelector(".equipped-weapon-reserve");
		if (clip) clip.textContent = String(Math.max(0, Number(payload.clip) || 0));
		if (reserve) reserve.textContent = String(Math.max(0, Number(payload.reserve) || 0));
	}
}

window.renderEquippedWeaponsPanel = renderEquippedWeaponsPanel;
window.refreshEquippedWeaponsPanel = refreshEquippedWeaponsPanel;
window.scheduleEquippedWeaponsPanelRefresh = scheduleEquippedWeaponsPanelRefresh;

function updateWeaponHud(payload = {}) {
	const root = document.querySelector("#weapon-hud");
	const image = document.querySelector("#weapon-hud-image");
	const clip = document.querySelector("#weapon-hud-clip");
	const reserve = document.querySelector("#weapon-hud-reserve");
	if (!root || !image || !clip || !reserve) return;

	const itemImage = payload.png || payload.item || "";
	clip.textContent = String(Math.max(0, Number(payload.clip) || 0));
	reserve.textContent = String(Math.max(0, Number(payload.reserve) || 0));

	if (itemImage) {
		const nextSrc = `${window.imageUrl}${itemImage}.png`;
		if (image.dataset.src !== nextSrc) {
			image.dataset.src = nextSrc;
			image.onerror = () => {
				image.onerror = null;
				image.src = "./images/weapon.svg";
			};
			image.src = nextSrc;
		}
	}

	clearTimeout(weaponHudHideTimer);
	root.classList.remove("is-hidden", "is-hiding");
	root.setAttribute("aria-hidden", "false");
	requestAnimationFrame(() => root.classList.add("is-visible"));
	updateEquippedWeaponAmmoFromHud(payload);
}

function hideWeaponHud() {
	const root = document.querySelector("#weapon-hud");
	if (!root) return;

	clearTimeout(weaponHudHideTimer);
	root.classList.remove("is-visible");
	root.classList.add("is-hiding");
	root.setAttribute("aria-hidden", "true");

	weaponHudHideTimer = setTimeout(() => {
		root.classList.add("is-hidden");
		root.classList.remove("is-hiding");
	}, 220);
}

function setQuickHotbarVisible(root) {
	clearTimeout(quickHotbarHideTimer);
	root.classList.remove("is-hidden", "is-fading");
	requestAnimationFrame(() => root.classList.add("is-visible"));
}

function hideQuickHotbar() {
	const root = document.querySelector("#quick-hotbar");
	if (!root) return;

	quickHotbarHeld = false;
	clearTimeout(quickHotbarTimer);
	clearTimeout(quickHotbarHideTimer);
	root.classList.add("is-fading");
	root.classList.remove("is-visible");

	quickHotbarHideTimer = setTimeout(() => {
		root.classList.add("is-hidden");
		root.classList.remove("is-fading");
	}, 350);
}

function renderQuickHotbar(payload = {}, held = false) {
	const root = document.querySelector("#quick-hotbar");
	const slotsRoot = document.querySelector("#quick-hotbar .quick-hotbar-slots");
	if (!root || !slotsRoot) return;

	const slots = payload.slots || [];
	const activeSlot = Number(payload.active_slot || 0);
	const ammo = payload.active_ammo || null;

	slotsRoot.innerHTML = "";
	for (let i = 1; i <= 5; i++) {
		const data = slots[i - 1] || slots[i] || { slot: i, empty: true };
		const item = data.item || "";
		const image = data.png || item;
		const isActive = activeSlot === i;
		const isWeapon = data.type === "equip";
		const amountText = isActive && isWeapon && ammo
			? `${ammo.clip ?? 0} / ${ammo.reserve ?? 0}`
			: (!data.empty && data.amount != null ? `${data.amount}x` : "");

		const slot = document.createElement("div");
		slot.className = `quick-hotbar-slot${isActive ? " is-active" : ""}${data.empty ? " is-empty" : ""}`;
		slot.innerHTML = `
			<div class="quick-hotbar-key">${i}</div>
			${image ? `<img class="quick-hotbar-item" src="${window.imageUrl}${image}.png" alt="" onerror="this.style.opacity='.18'">` : ""}
			${amountText ? `<div class="quick-hotbar-amount">${amountText}</div>` : ""}
			${isActive ? '<div class="quick-hotbar-equipped">EQUIPADO</div>' : ""}
		`;
		slotsRoot.appendChild(slot);
	}

	clearTimeout(quickHotbarTimer);
	clearTimeout(quickHotbarHideTimer);
	quickHotbarHeld = held || quickHotbarHeld;
	setQuickHotbarVisible(root);

	// TAB hold mode has no automatic timeout. It remains visible for exactly
	// as long as the client reports that TAB is physically held.
	if (held || quickHotbarHeld) return;

	quickHotbarTimer = setTimeout(() => {
		hideQuickHotbar();
	}, 2000);
}

const Routes = {
	SHOW_QUICK_HOTBAR: async (payload) => {
		renderQuickHotbar(payload, false);
	},
	SHOW_QUICK_HOTBAR_HOLD: async (payload) => {
		quickHotbarHeld = true;
		renderQuickHotbar(payload, true);
	},
	HIDE_QUICK_HOTBAR: async () => {
		hideQuickHotbar();
	},
	UPDATE_WEAPON_HUD: async (payload) => {
		updateWeaponHud(payload);
	},
	HIDE_WEAPON_HUD: async () => {
		hideWeaponHud();
	},
	OPEN_INVENTORY: async (payload) => {
		$("#inventory").removeClass("single-inventory");
		const userInventory = await Client("GET_INVENTORY");
		window.classInstances.weapons = new Weapons(await Client("GET_WEAPONS"));
		window.classInstances.left = new Inventory(userInventory);
		const pickupData = await Client("GET_PICKUPS");
		if(pickupData.inventory && Object.keys(pickupData.inventory).length > 0){
			window.classInstances.right = new Pickup(pickupData);
		}else{
			$("#inventory").addClass("single-inventory");
			$(".left-main").css("display", "flex");
			for (const el of document.querySelectorAll(".onlyInventory")) {
				el.style.display = "flex";
			}
		}
		$("#inventory").show();
		if ($("#inventory").hasClass("single-inventory")) {
			await refreshEquippedWeaponsPanel();
		}
		document.querySelector('.chest-title').innerHTML = 'Chão'
	},
	UPDATE_PICKUP: async (payload) => {
		if (window.classInstances?.right?.pickup) {
			const pickupData = await Client("GET_PICKUPS");
			window.classInstances.right = new Pickup(pickupData);
		}
	},
	OPEN_CHEST: async (payload) => {
		$("#inventory").removeClass("single-inventory");
		$(".left-main").css("display", "none");
		const userInventory = await Client("GET_INVENTORY");
		window.classInstances.left = new Inventory(userInventory);
		window.classInstances.right = new Chest(payload);
		// document.querySelector('.chest-title').innerHTML = 'Báu'
		$("#inventory").show();
	},
	CLOSE_INVENTORY: async (payload) => {
		$("#inventory").removeClass("single-inventory");
		const ignoreRight = payload.ignoreRight || false;
		Client("CLOSE_INVENTORY", {
			right: ignoreRight || (window.classInstances.hasOwnProperty("right") && !window.classInstances?.right?.pickup),
		});
		window.classInstances = {};
		$(".left-main").css("display", "none");
		$(".add-main").css("display", "none");

		$("#inventory").hide();
	},
	OPEN_INSPECT: async (payload) => {
		$("#inventory").removeClass("single-inventory");
		$(".left-main").css("display", "none");
		window.classInstances.left = new Inventory(payload.source);
		window.classInstances.right = new Inspect(payload.target);
		$("#inventory").show();
		document.querySelector('.chest-title').innerHTML = 'Revista'
	},
	OPEN_SHOP: async (payload) => {
		$("#inventory").removeClass("single-inventory");
		$(".left-main").css("display", "none");
		const userInventory = await Client("GET_INVENTORY");
		window.classInstances.left = new Inventory(userInventory);
		window.classInstances.right = new Shop(payload);
		$("#inventory").show();
		$('.weight-wrapper-right').css('display', 'none')
		document.querySelector('.chest-title').innerHTML = 'Loja de departamento'
	},
	FORCE_UPDATE_INVENTORY: async (payload) => {
		if (window.classInstances.left && $("#inventory").is(":visible")) {
			const userInventory = await Client("GET_INVENTORY");
			window.classInstances.left = new Inventory(userInventory);
			if ($("#inventory").hasClass("single-inventory")) scheduleEquippedWeaponsPanelRefresh(0);
		}
	},
};

$(() => {
	window.addEventListener("message", async ({ data }) => {
		const { route, payload = {} } = data;
		if (!globalThis.Config && route !== "SHOW_QUICK_HOTBAR" && route !== "UPDATE_WEAPON_HUD" && route !== "HIDE_WEAPON_HUD") {
			globalThis.Config = await Client("REQUEST_ITEMS_CONFIG");
		}
		if (Routes[route]) {
			try {
				await Routes[route](payload);
			} catch (err) {
				
				
			}
		}
	});

	document.addEventListener("keydown", ({ key }) => {
		if (key === "Escape") {
			Client("CLOSE_INVENTORY", {
				right: window.classInstances.hasOwnProperty("right"),
			});
			window.classInstances = {};
			$('.weight-wrapper-right').css('display', 'block')
			$(".left-main").css("display", "none");
			$(".add-main").css("display", "none");

			$("#inventory").hide();
		}
	});

	if (!window.invokeNative) {
		$("#inventory").show();
		globalThis.Config = {
			["radio"]: {
				index: "radio",
				item: 'radio',
				name: "Hammer",
				png: "radio",
				weight: 3.0,
				type: "equip"
			},
		}
		window.classInstances.left = new Inventory({
			inventory: {
				"6": {
					item: 'radio',
					amount: 10
				}
			},
			weight: 0,
			max_weight: 0,
			profile: {
				first_name: '',
				last_name: '',
				age: 0,
				phone: '',
			}
		})
	}
});

async function useHotbarItemFromUI(item, slot, amount = 1) {
	const numericSlot = Number(slot);
	const itemType = globalThis.Config?.[item]?.type;

	if (!Number.isInteger(numericSlot) || numericSlot < 1) {
		Notify("Slot de inventário inválido.", "error");
		return false;
	}

	// Weapons are intentionally exclusive to the quick slots. Ammo may be
	// consumed from any inventory slot while the matching weapon is equipped.
	if (itemType === "equip" && numericSlot > 5) {
		Notify("Mova a arma para um dos slots rápidos de 1 a 5 para equipá-la.", "error");
		return false;
	}

	const response = await Client("HOTBAR_USE_SLOT", {
		slot: String(slot),
		item,
		amount: Number(amount) || 1,
	});

	if (response?.error) {
		Notify(response.error, "error");
		return false;
	}

	if (response?.used_amount > 0 && window.classInstances.left?.items?.[String(slot)]) {
		window.classInstances.left.removeItem(String(slot), response.used_amount);
	}

	if (response?.hotbar && $("#inventory").hasClass("single-inventory")) {
		renderEquippedWeaponsPanel(response.hotbar);
	} else if ($("#inventory").hasClass("single-inventory")) {
		scheduleEquippedWeaponsPanelRefresh();
	}

	if (window.classInstances.left) {
		window.classInstances.weapons = new Weapons(await Client("GET_WEAPONS"));
	}

	return response || false;
}

window.useHotbarItemFromUI = useHotbarItemFromUI;

function Close() {
	$("#inventory").removeClass("single-inventory");
	Client("CLOSE_INVENTORY", {
		right: window.classInstances.hasOwnProperty("right"),
	});
	$('.weight-wrapper-right').css('display', 'block')
	window.classInstances = {};
	$(".left-main").css("display", "none");
	$(".add-main").css("display", "none");

	$("#inventory").hide();
}

$(".action-button").click(async function () {
	if (!globalThis.isOnline) {
		Notify("Sem conexão com a internet!", "error");
		return;
	}

	if (!globalThis.SelectedItem || globalThis.SelectedItem.side !== "left")
		return Notify("Selecione um item do seu inventário primeiro!", "error");
	let { item, id } = globalThis.SelectedItem;
	if (!window.classInstances.left.items[id]) {
		id = window.classInstances.left.findSlotByItem(item);
		if (!id)
			return Notify("Selecione um item do seu inventário primeiro!", "error");
	}
	let inputValue =
		Number.parseInt($(".input-frame").val()) > 0
			? Number.parseInt($(".input-frame").val())
			: globalThis.SelectedItem.amount;
	inputValue =
		inputValue > globalThis.SelectedItem.amount
			? globalThis.SelectedItem.amount
			: inputValue;

	const action = $(this).data("route");
	const itemType = globalThis.Config[item]?.type;

	if (action === "USE_ITEM" && (itemType === "equip" || itemType === "recharge")) {
		await useHotbarItemFromUI(item, id, inputValue);
		return;
	}

	const response = await Client(action, {
		slot: id,
		item: item,
		amount: inputValue,
	});
	if (typeof response !== "boolean" && response?.error) {
		Notify(response.error, "error");
		return;
	}
	if (!response) {
		return;
	}
	if (response) {
		window.classInstances.left.removeItem(
			id,
			response?.used_amount || inputValue,
		);
		if (
			action === "USE_ITEM" &&
			(globalThis.Config[item]?.type === "equip" ||
				globalThis.Config[item]?.type === "recharge")
		) {
			window.classInstances.weapons = new Weapons(await Client("GET_WEAPONS"));
		}
	}
});

$(document).on("click", ".slot-left", function () {
	window.classInstances.left.selectItem("left", $(this).data("id"));
});

$(document).on("click", ".slot-right", function () {
	window.classInstances.right.selectItem("right", $(this).data("id"));
});

async function Client(route, body = {}) {
	const res = await fetch(`http://${window.GetParentResourceName()}/${route}`, {
		method: "POST",
		headers: {
			"Content-type": "application/json; charset=UTF-8",
		},
		body: JSON.stringify(body),
	});

	const response = await res.json();
	if (route === "USE_ITEM" && !window.classInstances.left) return false;
	return response;
}

const NotifysType = {
	error: "linear-gradient(to right, #ff3737c7, #b02020c7)",
	success: "linear-gradient(to right, #56ab2f, #a8e063)",
}

function Notify(text, type) {
	Client("PLAY_SOUND", { sound: type });
	Toastify({
		text: text,
		className: type,
		duration: 3000,
		style: {
			"font-family": "Roboto Condensed",
			"font-weight": "350",
			background:
				NotifysType[type] || "linear-gradient(to right, #414d0b, #727a17)",
		},
	}).showToast();
}

function openStore() {
	fetch('https://inventory/openStore', { method: 'POST' })
}

/* if (!window.invokeNative) {
	document.querySelector("#inventory").style.display = 'block'
	$(".slot").droppable({
		accept: ".slot-item",
		drop: async (event, ui) => {
			const self = window.classInstances[ui.draggable.data("side")];
			if (!self) return;
			const id = ui.draggable.data("id");
			await self.changeItemPos(
				{ side: ui.draggable.data("side"), id },
				{ side: event.target.dataset.side, id: event.target.dataset.id },
				event.ctrlKey
					? "ctrl"
					: event.ctrlKey || event.shiftKey
						? "shift"
						: event.shiftKey,
			);
			if (ui.draggable.data("side") !== event.target.dataset.side) {
				window.classInstances[event.target.dataset.side].selectItem(
					event.target.dataset.side,
					event.target.dataset.id,
				);
			} else {
				self.selectItem(event.target.dataset.side, event.target.dataset.id);
			}
		},
	});
}

if (!window.invokeNative) {
	document.querySelector('.profile-wrapper').style.display = 'flex'
} */
