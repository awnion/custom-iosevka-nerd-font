# Custom Iosevka Nerd Font

![](https://github.com/awnion/custom-iosevka-nerd-font/blob/master/docs/imgs/iosevka-custom-dark.png?raw=true)
![](https://github.com/awnion/custom-iosevka-nerd-font/blob/master/docs/imgs/iosevka-custom-light.png?raw=true)

### Motivation

* need to control original Iosevka styles
* don't need WOFF
* don't need italic and oblique versions (so can speed up compilation)
* need only specific font weights (e.g. 200 300 400 500)
* need to fake bold weight to 500
* need specific base font width
* need nerd font version

### Key modifications

* Changed m i l % and others
* Changed font weights (e.g. "bold" has weight 500)
* No italic and oblique versions by default (can be included optionally)
* Base font shape width is `6`

For more options edit: `private-build-plans.toml` and build

### Build it yourself with Docker

```
./build.sh
```

Instal on Mac
```
./install_mac.sh
# or 
# cp -f -v build_dir/*.ttf ~/Library/Fonts/
```

vscode settings.json
```
...
"editor.fontFamily": "Iosevka Nerd Font, Iosevka Custom",
"editor.fontWeight": "400",
"editor.fontSize": 16,
"editor.lineHeight": 21,
...
```

### Links

* Iosevka webpage https://typeof.net/Iosevka/
* Build Iosevka font using docker https://github.com/ejuarezg/containers/tree/master/iosevka_font#container-method
* Nerd Font patcher https://github.com/ryanoasis/nerd-fonts
