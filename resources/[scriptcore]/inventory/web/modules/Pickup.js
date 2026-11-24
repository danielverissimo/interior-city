class Pickup extends Inventory {
    pickup;
    constructor(data, side = "right") {
        super(data, side, true);
        this.pickup = true;
        document.querySelector("#right").style.display = "block";
    }

    async refreshGroundInventory() {
        const inventory = await Client("GET_INVENTORY");
        const pickups = await Client("GET_PICKUPS");
        if (!window.classInstances.left || !window.classInstances.right?.pickup) return;
        window.classInstances.left = new Inventory(inventory);
        window.classInstances.right = new Pickup(pickups);
    }

    async takeItem(from_slot, amount, to_slot) {
        const entry = this.items[String(from_slot)];
        if (!entry || this.pending) return false;
        this.pending = true;
        try {
            amount = Number.isInteger(Number(amount)) && Number(amount) > 0
                ? Math.min(Number(amount), entry.amount) : entry.amount;
            const response = await Client("TAKE_PICKUP", {
                id: entry.id,
                amount,
                slot: String(to_slot),
            });
            if (response?.error) Notify(response.error, "error");
            await this.refreshGroundInventory();
            return response === true;
        } finally {
            this.pending = false;
        }
    }

    async putItem(from_slot, amount, to_slot) {
        const entry = window.classInstances.left?.items[String(from_slot)];
        if (!entry || this.pending) return false;
        this.pending = true;
        try {
            amount = Number.isInteger(Number(amount)) && Number(amount) > 0
                ? Math.min(Number(amount), entry.amount) : entry.amount;
            const response = await Client("DROP_ITEM", { slot: String(from_slot), amount });
            if (response?.error) Notify(response.error, "error");
            await this.refreshGroundInventory();
            return response === true;
        } finally {
            this.pending = false;
        }
    }
}