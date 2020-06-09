![](https://github.com/awnion/myfonts/blob/master/imgs/iosevka-custom.png?raw=true)

# myfonts

### Key modifications


* Changed m i l % and others
* No italic and oblique versions included by default
* Changed font weights (e.g. "bold" has weight 500)

See iosevka/private-build-plans.toml for details

### Build && Install

```
./build.sh
./patch.sh
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
"editor.fontFamily": "Iosevka Nerd Font",
"editor.fontWeight": "300",
"editor.fontSize": 17,
"editor.lineHeight": 22,
...
```

### Links

Build Iosevka font using docker
https://github.com/ejuarezg/containers/tree/master/iosevka_font#container-method
https://github.com/ryanoasis/nerd-fonts -- font patcher
