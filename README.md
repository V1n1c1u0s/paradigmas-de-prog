
---

## 🛰️ Morse Converter

> Conversor de texto para código Morse.  
> Desenvolvido no **Arch Linux** com **Hyprland**!

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=white&style=for-the-badge)
![Hyprland](https://img.shields.io/badge/Hyprland-00AEFF?logo=wayland&logoColor=white&style=for-the-badge)
![Free Pascal](https://img.shields.io/badge/Free%20Pascal-92201F?logo=freebsd&logoColor=white&style=for-the-badge)

---

## ✨ Features

- Conversão de texto para código Morse
- Interface simples e direta
- Compatível com ambientes Wayland (testado no Hyprland)

---

## ⚙️ Requisitos

Antes de compilar e rodar o programa, você precisa instalar:

```bash
sudo pacman -S fpc alsa-utils
```

| Pacote        | Função                                      |
|---------------|---------------------------------------------|
| `fpc`         | Compilador Free Pascal para gerar o binário |
| `alsa-utils`  | Suporte de som para ouvir o morse gerado    |

---

## 🛠️ Como Compilar e Rodar

1. Clone ou baixe o repositório.

```bash
git clone https://github.com/V1n1c1u0s/paradigmas-de-prog.git
```

2. Compile o código:

```bash
fpc morseconverter.pas
```

3. Execute o software:

```bash
./morseconverter
```

---