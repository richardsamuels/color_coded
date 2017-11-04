color_goded: 
---

Like [jeaye/color_coded](https://github.com/jeaye/color_coded) but for golang

Example vim-plug config
```
            Plug 'richardsamuels/color_goded', {
                        \ 'for': ['go']
                        \ 'do': 'mkdir build && cd build && ninja -G "Ninja" . .. && ninja install'
                        \ }
```

Build instructions `mkdir build && cd build && ninja -G "Ninja" . .. && ninja install'`
