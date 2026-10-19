-- 01_font: custom title font, reused from the author's own heartshooter cart.
-- The 2048 font bytes live raw in the cart's (otherwise unused) map region and
-- are copied into the font area at boot. Keeping them out of the code block is
-- what lets the cart fit the 15360-byte compressed-code limit (section 1.5 of
-- the PICO-8 manual) and therefore export to a web player.
--   regenerate with: python common/tools/gen_fontmap.py chapters/ch01/ch01.p8
memcpy(0x5600,0x2000,2048)
