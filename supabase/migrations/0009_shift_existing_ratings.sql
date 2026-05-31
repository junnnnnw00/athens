-- Shift existing ratings up by 200 Elo since user likes all their rated songs
UPDATE ratings SET elo = elo + 200;
