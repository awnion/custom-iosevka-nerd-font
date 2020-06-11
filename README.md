![](https://github.com/awnion/myfonts/blob/master/imgs/iosevka-custom-dark.png?raw=true)
![](https://github.com/awnion/myfonts/blob/master/imgs/iosevka-custom-light.png?raw=true)

# myfonts

### Key modifications


* Changed m i l % and others
* No italic and oblique versions included by default
* Changed font weights (e.g. "bold" has weight 500)

See iosevka/private-build-plans.toml for details

### Build && Install

```
./build_iosevka_custom.sh
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

Build Iosevka font using docker
https://github.com/ejuarezg/containers/tree/master/iosevka_font#container-method
https://github.com/ryanoasis/nerd-fonts -- font patcher
