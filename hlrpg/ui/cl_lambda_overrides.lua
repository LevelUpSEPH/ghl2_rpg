-- hlrpg/ui/cl_lambda_overrides.lua
-- Lambda keeps hinting "Press F1 to open gamemode settings menu" until its menu has been opened once.
-- That menu is disabled (sv_lambda_overrides.lua), so mark it as already opened to silence the hint.

cookie.Set("LambdaMenuOpened", 1)
