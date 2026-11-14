# BlueShift

A World of Warcraft addon for **WoW Forever** that moves the blue Battle.net notifications (friend came online or went offline, broadcasts, friend requests) wherever you want them and locks them there.

*Deutsche Beschreibung weiter unten.*

## Usage

1. Copy the `BlueShift` folder to `World of Warcraft/_forever_/Interface/AddOns/` and restart the game.
2. Type `/blueshift`. A blue box appears where the notifications show up.
3. Drag the box to the place you want.
4. Right click the box, or type `/blueshift` again, to lock the position.

From then on the notifications appear at that spot, for all your characters.

- `/blueshift unlock` and `/blueshift lock` set the state directly.
- `/blueshift reset` puts the notifications back above the chat.
- The same is available under *Options > AddOns > BlueShift*.

## Good to know

- Only the Battle.net notifications are moved. Other notifications above the chat stay where the game puts them; one that the game stacks onto a visible Battle.net notification moves along with it.
- The notification grows upwards from the saved spot when it has more lines.
- Texts are in English, on German clients in German.

For development, `tools/install.sh "<path to Interface/AddOns>"` copies just the addon files from a clone of this repository.

## License

[MIT](LICENSE)

---

## Deutsch

Ein Addon für **WoW Forever**, das die blauen Battle.net-Benachrichtigungen (Freund online oder offline, Rundnachrichten, Freundschaftsanfragen) an eine beliebige Stelle verschiebt und dort fixiert.

1. Den Ordner `BlueShift` nach `World of Warcraft/_forever_/Interface/AddOns/` kopieren und das Spiel neu starten.
2. `/blueshift` eingeben. Ein blauer Kasten erscheint dort, wo die Benachrichtigungen auftauchen.
3. Den Kasten an die gewünschte Stelle ziehen.
4. Mit Rechtsklick auf den Kasten oder erneut `/blueshift` die Position fixieren.

Ab dann erscheinen die Benachrichtigungen an dieser Stelle, für alle Charaktere. `/blueshift unlock` und `/blueshift lock` setzen den Zustand direkt, `/blueshift reset` setzt die Benachrichtigungen zurück über den Chat. Dasselbe gibt es unter *Optionen > AddOns > BlueShift*.

Verschoben werden nur die Battle.net-Benachrichtigungen. Andere Meldungen über dem Chat bleiben, wo das Spiel sie hinsetzt; stapelt das Spiel eine davon auf eine sichtbare Battle.net-Benachrichtigung, wandert sie mit.
