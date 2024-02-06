document.addEventListener('DOMContentLoaded', (event) => {
    // Add event listeners or other initialization here
});

// Listen for NUI messages.
window.addEventListener('message', (event) => {

    // If message type is 'openInventory' toggle inventory window. 
    if (event.data.type === 'openInventory') {
        toggleNuiWindow(event.data.isVisible);

        if (event.data.isVisible) {
            let slotCount = 0;

            $('#inventoryWindow').append('<h3 align="center">Inventory</h3>');

            for (const [key, value] of Object.entries(event.data.inventory)) {
                slotCount = ++slotCount;
                
                $('#inventoryWindow').append(
                    `<div id="Slot${slotCount}" class="itemSlot item_${key}">
                        <p id="${key}_amount" class="amount">${value}</p>
                    </div>`
                );
                //$(`#Slot${slotCount}`).css("background-image", "url('./img/inventory_marijuana.png')");
            }

            slotCount = 0;

            $(document).ready(function(){
				
				$('.item_ammoBox').on('click', function(){
					$.post("https://playerMgr/useAmmoBox", JSON.stringify({}));
    
					let ammoBoxAmount = Number($('#ammoBox_amount').text()) - 1
					$('#ammoBox_amount').empty();
					$('#ammoBox_amount').append(ammoBoxAmount);

					if(ammoBoxAmount === 0){
						$('.item_ammoBox').remove()
					}
				});
				
                $('.item_armor').on('click', function(){
                    $.post("https://playerMgr/useArmor", JSON.stringify({}));
                    
                    let armorAmount = Number($('#armor_amount').text()) - 1
                    $('#armor_amount').empty();
                    $('#armor_amount').append(armorAmount);

                    if(armorAmount === 0){
                        $('.item_armor').remove()
                    }
                });

                $('.item_parachute').on('click', function(){
                    $.post("https://playerMgr/useParachute", JSON.stringify({}));
                    
                    let parachuteAmount = Number($('#parachute_amount').text()) - 1
                    $('#parachute_amount').empty();
                    $('#parachute_amount').append(parachuteAmount);

                    if(parachuteAmount === 0){
                        $('.item_parachute').remove()
                    }
                });
				
				
            });
        }
    }

    // If message type is 'updateMoneyHUD'.
    if (event.data.type === 'updateMoneyHUD') {
        $('#cash').empty();
        $('#cash').append('$ ' + event.data.cash);

        $('#bank').empty();
        $('#bank').append('$ ' + event.data.bank);
    }
});

// Listen for escape's keydown event. Trigger "exit" callback function on the client.
window.addEventListener('keydown', function (event) {
    if (event.keyCode === 27) {
        console.log('Esc key pressed. Sending NUI exit message.');
        $.post("https://playerMgr/exit", JSON.stringify({}));
        $('#inventoryWindow').empty();
    }
});

// Function to toggle #inventoryWindow CSS properties on/off when the window is opened or closed.
function toggleNuiWindow(isVisible) {
    const inventoryWindow = document.getElementById('inventoryWindow');
    if (isVisible) {
        inventoryWindow.style.display = 'inline';
    } else {
        inventoryWindow.style.display = 'none';
    }
}