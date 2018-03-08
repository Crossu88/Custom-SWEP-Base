--[[---------------------------------------------------------
   Name: SWEP:DoDrawCrosshair()
   Desc: Replaces default crosshair with dynamic crosshair
---------------------------------------------------------]]--

function SWEP:DoDrawCrosshair( x, y )
    -- Equation calculates the gap between crosshairs
    local gap = ((y*self:GetNWFloat("AimCone"))/(self.Owner:GetFOV()/100))
	surface.SetDrawColor( 0, 250, 255, 255 )
    surface.DrawLine( x + gap, y, x + gap + 10, y)
    surface.DrawLine( x - gap, y, x - gap - 10 , y)
    surface.DrawLine( x, y + gap, x , y + gap + 10)
    surface.DrawLine( x, y - gap, x , y - gap - 10)
	return true
end