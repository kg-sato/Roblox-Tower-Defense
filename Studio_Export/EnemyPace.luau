--!strict
-- EnemyPace (2026-10-29): a shared slot. GameClient puts its `enemies` table here so StarterPlayerScripts.PaceClient can apply "Pace" events to it.
return { enemies = nil :: { [number]: any }? }