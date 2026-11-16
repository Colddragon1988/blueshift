# BlueShift

A World of Warcraft addon for **WoW Forever** that moves the blue notifications (friend came online or went offline, broadcasts, friend requests, the layer change warning) wherever you want them and locks them there.

*Deutsche Beschreibung weiter unten.*

## Usage

1. Copy the `BlueShift` folder to `World of Warcraft/_forever_/Interface/AddOns/` and restart the game.
2. Type `/blueshift`. Two blue boxes appear: one where the notifications show up, one for the layer change warning.
3. Drag each box to the place you want.
4. Right click a box, or type `/blueshift` again, to lock the positions.

From then on the notifications appear at those spots, for all your characters.

- `/blueshift unlock` and `/blueshift lock` set the state directly.
- `/blueshift reset` puts everything back above the chat.
- The same is available under *Options > AddOns > BlueShift*.

## Good to know

- All blue notifications are moved: the Battle.net ones, the voice chat prompts, the play time alert and the layer change warning ("the world around you will change").
- The layer change warning has a box and a position of its own, independent of the other notifications. A box you never drag leaves its notification where the game puts it.
- When several notifications are visible at once, they stack upwards from the saved spot, as the game does it above the chat.
- The notification grows upwards from the saved spot when it has more lines.
- Texts are in English, on German clients in German.

For development, `tools/install.sh "<path to Interface/AddOns>"` copies just the addon files from a clone of this repository.

## License

[MIT](LICENSE)

---

## Deutsch

Ein Addon für **WoW Forever**, das die blauen Benachrichtigungen (Freund online oder offline, Rundnachrichten, Freundschaftsanfragen, Hinweis auf Layer-Wechsel) an eine beliebige Stelle verschiebt und dort fixiert.

1. Den Ordner `BlueShift` nach `World of Warcraft/_forever_/Interface/AddOns/` kopieren und das Spiel neu starten.
2. `/blueshift` eingeben. Zwei blaue Kästen erscheinen: einer dort, wo die Benachrichtigungen auftauchen, einer für den Hinweis auf den Layer-Wechsel.
3. Jeden Kasten an die gewünschte Stelle ziehen.
4. Mit Rechtsklick auf einen Kasten oder erneut `/blueshift` die Positionen fixieren.

Ab dann erscheinen die Benachrichtigungen an diesen Stellen, für alle Charaktere. `/blueshift unlock` und `/blueshift lock` setzen den Zustand direkt, `/blueshift reset` setzt alles zurück über den Chat. Dasselbe gibt es unter *Optionen > AddOns > BlueShift*.

Verschoben werden alle blauen Benachrichtigungen: die von Battle.net, die Sprachchat-Hinweise, der Spielzeit-Hinweis und der Hinweis auf den Layer-Wechsel („die Welt um dich herum wird sich ändern“). Dieser hat einen eigenen Kasten und eine eigene Position, unabhängig von den übrigen Benachrichtigungen. Ein Kasten, der nie gezogen wird, lässt seine Meldung dort, wo das Spiel sie hinsetzt. Sind mehrere Benachrichtigungen gleichzeitig sichtbar, stapeln sie sich von der gespeicherten Stelle aus nach oben.
