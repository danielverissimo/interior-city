function disableHiddenDropables() {
	$(".empty").each(function () {
		const elemTop = $(this).offset().top;
		const elemBottom = elemTop + $(this).outerHeight();

		const containerTop = $(".items-container").offset().top;
		const containerBottom = containerTop + $(".items-container").outerHeight();

		if ((elemBottom < containerTop || elemTop > containerBottom) && Number($(this).data('id')) > 5) {
			$(this).droppable("disable");
		} else {
			$(this).droppable("enable");
		}
	});
}

class Inventory {
	items;
	maxWeight = 0;
	currentWeight = 0;
	weightPercentage = 0;
	side;

	constructor(data, side = "left", pickup = undefined) {
		const { inventory, weight, max_weight, profile } = data;
		this.pickup = pickup;
		this.items = this.parseItems(inventory);
		this.maxWeight = max_weight;
		this.currentWeight = weight;
		this.weightPercentage = (this.currentWeight * 100) / this.maxWeight;
		this.side = side;
		this.slotHeight = 0;
		this.slotWidth = 0;

		
		document.querySelector('.profile-wrapper').style.display = 'flex'
		if (profile) {
			document.querySelector('#name-player').innerText = profile.name
			document.querySelector('#job-player').innerText = profile.job || 'Desempregado'

			if (profile.image_url) document.querySelector('#player-image').src = profile.image_url
		}
		
		if (side === "right") {
			for (const el of document.querySelectorAll(".onlyInventory")) {
				el.style.display = "none";
			}
		}
		this.renderSlots(side);
		this.renderInfos(side);
	}
	findSlotByItem(name, ignoreSlot) {
		let _slot;

		Object.keys(this.items).forEach((slot) => {
			if (
				this.items[slot].item === name &&
				(!ignoreSlot || !ignoreSlot.includes(slot))
			) {
				_slot = slot;
			}
		});

		return _slot;
	}
	refreshWeight() {
		
		if (this.side === "right" && window.classInstances[this.side]?.mode) {
			$(`.weight-wrapper-${this.side} span`).html("- <small>/ -</small>");
			return;
		}
		this.currentWeight = Object.values(this.items).reduce((total, num) => {
			if (num.weight) {
				return num.weight * num.amount + total;
			}
			return total;
		}, 0);
		if (this.side === "right" && this?.pickup) {
			$(`.weight-wrapper-${this.side} span`).html("");
			return;
		}
	
		$(`.weight-wrapper-${this.side} .progress-bar-fill`).css("width", `${this.currentWeight / this.maxWeight * 100}%`);
		$(`.weight-wrapper-${this.side} span`).html(
			`${this.currentWeight.toFixed(1)} <small>/ ${this.maxWeight} KG</small>`,
		);
	}
	parseItems(items) {
		Object.keys(items).forEach((slot) => {
			const itemName = items[slot].item;
			items[slot].name = globalThis.Config[itemName]?.name;
			if (!items[slot].name) {
				delete items[slot];
			} else {
				items[slot].key = itemName;
				items[slot].slot = slot;
				items[slot].weight = globalThis.Config[itemName]?.weight;
			}
		});
		return items;
	}

	renderSlots(target = "left") {
		$(`.slots-${target}`).html("");
		
		if(this.side === "left"){
			$(".hotbar-wrapper .slots").empty();
		}
		for (let i = 0; i < 58; i++) {
			const slot = i + 1;
			if (
				!this.items[slot.toString()] ||
				(this.items[slot.toString()] &&
					globalThis.Config[this.items[slot.toString()].item])
			) {
				const targetDiv = (this.side === "left" && i <= 4) ? `.slots-${target}` : `.slots-${target}`;

				if (this.items[slot.toString()]) {
					const item = this.items[slot.toString()];
					if (i <= 4 && this.side == 'left') {
						$('.hotbar-wrapper .slots').append(this.getItemHtml(item, target, slot));
					} else $(`${targetDiv}`).append(this.getItemHtml(item, target, slot));
				} else {
					if (i <= 4 && this.side == 'left') {
						$(`.hotbar-wrapper .slots`).append(
							`<div class="slot empty slot-${target}${slot}" data-side="${target}" data-id="${slot}"></div>`,
						);
					} else {
						$(`${targetDiv}`).append(
							`<div class="slot empty slot-${target}${slot}" data-side="${target}" data-id="${slot}"></div>`,
						);
					}
				}
			}
		}
		this.slotHeight = Math.floor($(`.slot-${target}`).height() / 2);
		this.slotWidth = Math.floor($(`.slot-${target}`).width() / 2);

		this.refreshWeight();
		this.updateDrag(target);
		if (this.side === "left" && typeof window.scheduleEquippedWeaponsPanelRefresh === "function") {
			window.scheduleEquippedWeaponsPanelRefresh();
		}
	}

	removeItem(slot, amount) {
		this.items[slot].amount -= amount;
		if (this.items[slot].item === "mochila") {
			if (this.maxWeight <= 25) {
				this.maxWeight = 50;
			} else if (this.maxWeight === 50) {
				this.maxWeight = 75;
			} else if (this.maxWeight === 75) {
				this.maxWeight = 90;
			}
		}
		if (this.items[slot].amount <= 0) {
			delete this.items[slot];
		}
		this.renderSlots(this.side);
	}
	formatWeight(weight){
		return `${weight.toFixed(1)}kg`;
	}
	getItemHtml(item, target, slot, method = "allDiv") {
		if (method === "onlyItems") {
			return `
            <p class="weight-item-inventory">${this.formatWeight(item.weight)}</p>
            <p class="amount-item-inventory">${
							item.price ? `R$${item.price}` : `${item.amount}x`
						}</p>
            <p class="name-item-inventory" title="${item.name}">${item.name}</p>
            <img src="http://127.0.0.1/images/${item.item}.png" onerror="this.onerror=null;this.src='./images/weapon.svg'"/>
            `;
		}
		return `
        <div class="slot slot-${target} slot-item slot-${target}${slot}" data-side="${target}" data-id="${slot}">
            <p class="weight-item-inventory">${this.formatWeight(item.weight)}</p>
            <p class="amount-item-inventory">${
							item.price ? `R$${item.price}` : `${item.amount}x`
						}</p>
            <p class="name-item-inventory" title="${item.name}">${item.name}</p>
            <img src="http://127.0.0.1/images/${item.item}.png" onerror="this.onerror=null;this.src='./images/weapon.svg'"/>
        </div>
        `;
	}

	renderInfos(side) {
		if (this.side === "right" && window.classInstances[this.side]?.mode) {
			$(".weight-right").html("-");
			$(`.inside-${this.side}`).css("width", `${(0 * 100) / 100}%`);
			return;
		}
		
		if(this.side === "right" && this?.pickup){
			$(".weight-right").html("-");
			return
		}

		this.refreshWeight();
		$(`.weight-wrapper-${this.side} p`).html(`${this.currentWeight.toFixed(1)} <span>/ ${this.maxWeight} KG</span>`,
		);
	}

	getItems() {
		return this.items;
	}

	selectItem(side, itemId) {
		if(this.side === "right") return;
		if (!this.items[itemId]) return;
		const item = { ...this.items[itemId], id: itemId, side };
		$(".slot").removeClass("slot-active");

		globalThis.SelectedItem = item;
		$(".name-box-middle").html(globalThis.SelectedItem.name);
		// $(".weight-box-middle").html(
		// 	`${(globalThis.SelectedItem.weight || 0).toFixed(1)} kg`,
		// );
		// $(".amount-box-middle").html(
		// 	globalThis.SelectedItem.amount
		// 		? `${globalThis.SelectedItem.amount}x`
		// 		: `R$${globalThis.SelectedItem.price}`,
		// );
		$(".image-grame").attr(
			"src",
			`http://127.0.0.1/images/${globalThis.SelectedItem.item}.png`,
		);
		$(`.slot-${side}${item.id}`).addClass("slot-active");
	}

	async changeItemPos(old, next, keyPressed) {
		let swapResponse = null;
		let forceInventoryRefresh = false;

		if (old.side === next.side) {
			old.item = this.items[old.id.toString()];
			next.item = this.items[next.id.toString()];
			let inputValue =
				Number.parseInt($(".input-frame").val()) > 0
					? Number.parseInt($(".input-frame").val())
					: old.item.amount;
			if (keyPressed === "ctrl" && old.item.amount % 2 === 0) {
				inputValue = old.item.amount / 2;
			} else if (keyPressed === "shift") {
				inputValue = 1;
			}
			if (inputValue > old.item.amount) {
				inputValue = old.item.amount;
			}
			if (old.side === "right" && (window.classInstances[old.side]?.mode || window.classInstances[old.side]?.pickup))
				return false;
			const response = !window.invokeNative ? true : 
				old.side === "right" ||
				(await Client("SWAP_SLOT", {
					from_slot: old.id,
					from_amount: inputValue,
					to_slot: next.id,
				}));
			if (!response || response?.success === false) {
				return false;
			}

			swapResponse = response;
			forceInventoryRefresh = response?.refresh_inventory === true;

			// The server snapshot is authoritative and is returned in the same
			// drag response, so the weapons sidebar changes immediately without
			// waiting for the inventory to be closed/reopened.
			if (response?.hotbar && typeof window.renderEquippedWeaponsPanel === "function") {
				window.renderEquippedWeaponsPanel(response.hotbar);
			}
			if (response?.warning) {
				Notify(response.warning, "error");
			}
			if (!next.item) {
				if (old.item.amount <= inputValue) {
					const html = $(`.slot-${old.side}${old.id}`).html();
					$(`.slot-${old.side}${old.id}`)
						.removeClass("slot-item")
						.addClass("empty")
						.html("");
					$(`.slot-${next.side}${next.id}`)
						.html(html)
						.removeClass("empty")
						.addClass("slot-item")
						.addClass(`slot-${next.side}`);
					this.items[next.id.toString()] = this.items[old.id.toString()];
					delete this.items[old.id.toString()];
				} else {
					this.items[old.id.toString()].amount -= inputValue;
					this.items[next.id.toString()] = {};
					Object.assign(
						this.items[next.id.toString()],
						this.items[old.id.toString()],
						{ amount: inputValue },
					);
					$(`.slot-${next.side}${next.id}`)
						.html(
							this.getItemHtml(
								this.items[next.id.toString()],
								next.side,
								next.id,
								"onlyItems",
							),
						)
						.removeClass("empty")
						.addClass("slot-item")
						.addClass(`slot-${next.side}`);
					$(`.slot-${old.side}${old.id}`)
						.html(
							this.getItemHtml(
								this.items[old.id.toString()],
								old.side,
								old.id,
								"onlyItems",
							),
						)
						.removeClass("empty")
						.addClass("slot-item")
						.addClass(`slot-${next.side}`);
				}
			} else if (old.item.item === next.item.item) {
				if (old.item.amount <= inputValue) {
					this.items[next.id.toString()].amount += inputValue;
					const html = this.getItemHtml(
						this.items[next.id.toString()],
						next.side,
						next.id,
						"onlyItems",
					);
					$(`.slot-${old.side}${old.id}`)
						.removeClass("slot-item")
						.addClass("empty")
						.html("");
					$(`.slot-${next.side}${next.id}`)
						.html(html)
						.removeClass("empty")
						.addClass("slot-item")
						.addClass(`slot-${next.side}`);
					delete this.items[old.id.toString()];
				} else {
					this.items[old.id.toString()].amount -= inputValue;
					this.items[next.id.toString()].amount += inputValue;
					Object.assign(
						this.items[next.id.toString()],
						this.items[old.id.toString()],
						{ amount: inputValue },
					);
					$(`.slot-${next.side}${next.id}`)
						.html(
							this.getItemHtml(
								this.items[next.id.toString()],
								next.side,
								next.id,
								"onlyItems",
							),
						)
						.removeClass("empty")
						.addClass("slot-item")
						.addClass(`slot-${next.side}`);
					$(`.slot-${old.side}${old.id}`)
						.html(
							this.getItemHtml(
								this.items[old.id.toString()],
								old.side,
								old.id,
								"onlyItems",
							),
						)
						.removeClass("empty")
						.addClass("slot-item")
						.addClass(`slot-${next.side}`);
				}
			} else if (old.item.item !== next.item.item) {
				const oldHtml = $(`.slot-${old.side}${old.id}`).html();
				const nextHtml = $(`.slot-${next.side}${next.id}`).html();
				$(`.slot-${next.side}${next.id}`).html(oldHtml);
				$(`.slot-${old.side}${old.id}`).html(nextHtml);
				const oldObj = JSON.parse(
					JSON.stringify(this.items[old.id.toString()]),
				);
				const nextObj = JSON.parse(
					JSON.stringify(this.items[next.id.toString()]),
				);
				nextObj.slot = next.id;
				oldObj.slot = old.id;
				this.items[next.id.toString()] = oldObj;
				this.items[old.id.toString()] = nextObj;
			}
			this.updateDrag(old.side);
		}
		if (old.side === "left" && next.side === "right") {
			old.item = this.items[old.id.toString()];
			let inputValue =
				Number.parseInt($(".input-frame").val()) > 0
					? Number.parseInt($(".input-frame").val())
					: old.item.amount;
			if (keyPressed === "ctrl" && old.item.amount % 2 === 0) {
				inputValue = old.item.amount / 2;
			} else if (keyPressed === "shift") {
				inputValue = 1;
			}
			if (inputValue > old.item.amount) {
				inputValue = old.item.amount;
			}
			await window.classInstances.right.putItem(old.id, inputValue, next.id);
		}

		if (old.side === "right" && next.side === "left") {
			if (window.classInstances.right.mode) {
				// Loja
				let inputValue =
					Number.parseInt($(".input-frame").val()) > 0
						? Number.parseInt($(".input-frame").val())
						: 1;
				if (keyPressed === "ctrl" && old.item.amount % 2 === 0) {
					inputValue = old.item.amount / 2;
				} else if (keyPressed === "shift") {
					inputValue = 1;
				}
				await window.classInstances.right.takeItem(old.id, inputValue, next.id);
			} else {
				old.item = window.classInstances.right.items[old.id.toString()];
				let inputValue =
					Number.parseInt($(".input-frame").val()) > 0
						? Number.parseInt($(".input-frame").val())
						: old.item.amount;
				if (keyPressed === "ctrl" && old.item.amount % 2 === 0) {
					inputValue = old.item.amount / 2;
				} else if (keyPressed === "shift") {
					inputValue = 1;
				}
				await window.classInstances.right.takeItem(old.id, inputValue, next.id);
			}
		}

		// Returning rounds from a weapon can create/increase an ammo stack in a
		// different slot. Re-read the inventory only in that special case so the
		// new ammo quantity is visible immediately as well.
		if (forceInventoryRefresh && old.side === "left") {
			const userInventory = await Client("GET_INVENTORY");
			window.classInstances.left = new Inventory(userInventory);
			if (swapResponse?.hotbar && typeof window.renderEquippedWeaponsPanel === "function") {
				window.renderEquippedWeaponsPanel(swapResponse.hotbar);
			}
		}
	}
	updateDrag(target) {
		$(`.slot-${target}`).draggable({
			disabled: false,
			containment: ".container",
			cursorAt: {
				top: Math.floor($(`.slot-${target}`).height() / 2),
				left: Math.floor($(`.slot-${target}`).width() / 2),
			},
			start: (event, ui) => {
				this.selectItem(
					event.currentTarget.dataset.side,
					event.currentTarget.dataset.id,
				);
				disableHiddenDropables()
			},
			opacity: 0.7,
			cursor: "grabbing",
			helper: "clone",
			revert: "invalid",
			hoverClass: 'item-selected'
		});

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

		$(".weapons-container").droppable({
			accept: ".slot-left",
			drop: async (event, ui) => {
				const self = window.classInstances[ui.draggable.data("side")];
				if (!self || ui.draggable.data("side") !== "left") return;
				if (!globalThis.SelectedItem || globalThis.SelectedItem.side !== "left")
					return Notify(
						"Selecione um item do seu inventário primeiro!",
						"error",
					);

				let { item, id } = globalThis.SelectedItem;
				const inputValue = 1;
				if (!window.classInstances.left.items[id]) {
					id = window.classInstances.left.findSlotByItem(item);
					if (!id)
						return Notify(
							"Selecione um item do seu inventário primeiro!",
							"error",
						);
				}
				if (globalThis.Config[item]?.type !== "equip") {
					Notify("Este item não pode ser equipado!", "error");
					return;
				}

				if (Number(id) < 1 || Number(id) > 5) {
					Notify("Mova a arma para um dos slots rápidos de 1 a 5.", "error");
					return;
				}

				await window.useHotbarItemFromUI(item, id, inputValue);
			},
		});

		$(".action-button").droppable({
			accept: ".slot-left",
			drop: async (event, ui) => {
				const self = window.classInstances[ui.draggable.data("side")];
				if (!self || ui.draggable.data("side") !== "left") return;
				self.selectItem("left", ui.draggable.data("id"));

				if (!globalThis.SelectedItem || globalThis.SelectedItem.side !== "left")
					return Notify(
						"Selecione um item do seu inventário primeiro!",
						"error",
					);
				let { item, id } = globalThis.SelectedItem;
				if (!window.classInstances.left.items[id]) {
					id = window.classInstances.left.findSlotByItem(item);
					if (!id)
						return Notify(
							"Selecione um item do seu inventário primeiro!",
							"error",
						);
				}
				let inputValue =
					Number.parseInt($(".input-frame").val()) > 0
						? Number.parseInt($(".input-frame").val())
						: globalThis.SelectedItem.amount;
				inputValue =
					inputValue > globalThis.SelectedItem.amount
						? globalThis.SelectedItem.amount
						: inputValue;

				const action = event.target.dataset.route;
				const itemType = globalThis.Config[item]?.type;

				if (action === "USE_ITEM" && (itemType === "equip" || itemType === "recharge")) {
					await window.useHotbarItemFromUI(item, id, inputValue);
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
						window.classInstances.weapons = new Weapons(
							await Client("GET_WEAPONS"),
						);
					}
				}
			},
		});

		$(".empty").draggable({
			disabled: true,
		});
	}
}
