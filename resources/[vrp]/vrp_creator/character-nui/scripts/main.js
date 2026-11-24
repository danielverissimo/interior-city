window.addEventListener("message", ({ data }) => {
  if (data.CharacterMode == true) {
    app.OpenCharacterMode();
  }
  if (data.CharacterMode == false) {
    app.CloseCharacterMode();
  }
  if (data.identity === true) identityForm.open(data);
  if (data.identity === false) identityForm.close();

  if (data.activationScreen === true) document.querySelector('#activationScreen').style.display = 'flex';
  if (data.activationScreen === false) document.querySelector('#activationScreen').style.display = 'none';
});

if (!window.invokeNative) {
  document.body.style.background = "#1c1c1c"
  window.postMessage({ identity: true }, "*")
  // window.postMessage({
  //   activationScreen: true
  // }, '*');
}