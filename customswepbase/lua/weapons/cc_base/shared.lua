SWEP.Spawnable              = true
SWEP.AdminOnly              = true

SWEP.Category               = "Custom Swep Base"
SWEP.PrintName              = "Custom Base"
SWEP.Author                 = "Crossu88"

SWEP.ViewModel              = "models/weapons/c_smg1.mdl"
SWEP.WorldModel             = "models/weapons/w_smg1.mdl"
SWEP.HoldType               = "ar2"

SWEP.BobScale               = 0
SWEP.SwayScale              = 0

SWEP.Slot                   = 1 

SWEP.Primary.Ammo           = "SMG1"
SWEP.Primary.ClipSize       = 30
SWEP.Primary.DefaultClip    = 90
SWEP.Primary.Automatic      = true

SWEP.Primary.FireRate       = 600
SWEP.Primary.AimCone        = 1
SWEP.Primary.MinCone        = 0.01
SWEP.Primary.MaxCone        = 0.1
SWEP.Primary.Damage         = 30
SWEP.Primary.Firemodes      = {"auto", "burst", "semi"}
SWEP.Primary.BurstAmount    = 3
SWEP.Primary.BurstDelay     = 0.2

SWEP.Secondary.Active       = false
SWEP.Secondary.Ammo         = "nil"
SWEP.Secondary.ClipSize     = 0
SWEP.Secondary.DefaultClip  = 0

--[[---------------------------------------------------------
   Name: SWEP:SetupDataTables()
   Desc: Creates data tables
---------------------------------------------------------]]--

function SWEP:SetupDataTables()
    self:NetworkVar( "Int",     0,  "PrimaryFiremode"   )
    self:NetworkVar( "Float",   0,  "LastUse"           )
end

--[[---------------------------------------------------------
   Name: SWEP:Initialize()
   Desc: Called when the swep is initialized
---------------------------------------------------------]]--

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )

    self.Primary.AimCone = self.Primary.MinCone

    --Always adds the safe Firemode to any weapon
    table.insert( self.Primary.Firemodes, 1, "safe")

    --Sets the Firemode to the first non safe Firemode
    self:SetPrimaryFiremode(2)

    self:SetLastUse(CurTime())
end

--[[---------------------------------------------------------
   Name: SWEP:Think()
   Desc: Called every tick
---------------------------------------------------------]]--

function SWEP:Think()
    -- Handles accuracy at all times
    self:HandleAccuracy()

    local t = Lerp( 0.5, self:GetNWFloat("AimCone"), self.Primary.AimCone )
    self:SetNWFloat("AimCone", t)

    -- Tracks the last time the use key was pressed to create a use key delay before reloading is allowed
    if self.Owner:KeyReleased( IN_USE ) then
        self:SetLastUse( CurTime() )
    end

    -- Cycles the Firemode
    if self.Owner:KeyDown( IN_USE ) and self.Owner:KeyPressed( IN_RELOAD ) then
        self:CycleFiremode()
    end

    -- Adds burst delay to bursts of any length
    if ( self:GetNWInt("ShotCount") > 0 ) and !self.Owner:KeyDown( IN_ATTACK ) then
        self:SetNextPrimaryFire( CurTime() + self.Primary.BurstDelay )
    end
end

--[[---------------------------------------------------------
   Name: SWEP:HandleAccuracy()
   Desc: Called every tick to deal with accuracy calculations
---------------------------------------------------------]]--

function SWEP:HandleAccuracy()
    local t = CurTime() - self:LastShootTime()
    self:SetNWFloat( "ShotInacc", math.Clamp(self:GetNWFloat("ShotInacc") - t, 0, self.Primary.FireRate/60) )


    local shotRate = (self.Primary.FireRate/60)
    local accClimb = (self.Primary.MaxCone - self.Primary.MinCone)/shotRate
    local curAcc = math.Clamp(self.Primary.MinCone + accClimb*self:GetNWFloat("ShotInacc"), self.Primary.MinCone, self.Primary.MaxCone)

    local l = Lerp( 0.5, self.Primary.AimCone, curAcc )
    
    self.Primary.AimCone = l

    --self:SetNWFloat( "AimCone", self.Primary.AimCone )

    print("t: "..t)
    print("ShotInacc: "..self:GetNWFloat("ShotInacc"))
    print("shotRate: "..shotRate)
    print("accClimb: "..accClimb)
    print("curAcc: "..curAcc)
    print(self.Primary.AimCone)
end

--[[---------------------------------------------------------
   Name: SWEP:ChangeFiremode()
   Desc: Called when +attack1 is pressed
---------------------------------------------------------]]--

function SWEP:CycleFiremode()
    -- Prevents cycling from being called more than once per press
    if not IsFirstTimePredicted() then return end

    -- Changes the Firemode and then plays a sound
    if ( self:GetPrimaryFiremode() >= #self.Primary.Firemodes ) or ( self:GetPrimaryFiremode() < 1 ) then
        self:SetPrimaryFiremode(1)
    else
        self:SetPrimaryFiremode( self:GetPrimaryFiremode() + 1 ) 
    end
    
    self:EmitSound( "Weapon_Pistol.Empty" )

    -- Sets local firearm variable
    local Firemode = self.Primary.Firemodes[self:GetPrimaryFiremode()]

    -- Sets the gun to semi or automatic operation
    if ( Firemode == "semi" ) then
        self.Primary.Automatic = false
    else
        self.Primary.Automatic = true
    end

    print(Firemode)
end

--[[---------------------------------------------------------
   Name: SWEP:CanReload( )
   Desc: Called when player reloads to check if possible
---------------------------------------------------------]]--

function SWEP:CanReload()
    -- Can not reload if use is being pressed
    if self.Owner:KeyDown( IN_USE ) or ( (CurTime() - self:GetLastUse()) < 0.2 ) then
        return false 
    end

    return true
end

--[[---------------------------------------------------------
   Name: SWEP:Reload( )
   Desc: Called when player reloads
---------------------------------------------------------]]--

function SWEP:Reload()
    -- Checks to see if reload is allowed
    if !self:CanReload() then return end

    -- Resets shot inaccuracy
    self:SetNWFloat( "ShotInacc", 0 )

	self.Weapon:DefaultReload( ACT_VM_RELOAD );
end

--[[---------------------------------------------------------
   Name: SWEP:PrimaryAttack()
   Desc: Called when +attack1 is pressed
---------------------------------------------------------]]--

function SWEP:PrimaryAttack()
	-- Make sure we can shoot first
    if ( !self:CanPrimaryAttack() ) then return end
    
    -- Ticks up the inaccuracy float to calculate accuracy with
    self:SetNWFloat( "ShotInacc", self:GetNWFloat("ShotInacc") + 1)

    -- Ticks up the shot count in order to keep track of the bullets fired in a burst
    self:GetNWInt( "ShotCount", self:GetNWInt("ShotCount") + 1 )

	-- Play shoot sound
	self.Weapon:EmitSound("Weapon_AR2.Single")
	
	-- Damage, Projectiles per shot, Aimcone
	self:ShootBullet( 150, 1, self.Primary.AimCone )
	
	-- Remove 1 bullet from our clip
    self:TakePrimaryAmmo( 1 )
    
    -- Causes a delay before the next bullet can fire
    self:SetNextPrimaryFire( CurTime() + (60 / self.Primary.FireRate) )

    -- Sets last shoot time
    self:SetLastShootTime()
end

--[[---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack()
   Desc: Determines whether the weapon can use primary fire
---------------------------------------------------------]]--
function SWEP:CanPrimaryAttack()

    if ( self:GetPrimaryFiremode() == 1 ) then return false end

    if ( self.Primary.Firemodes[self:GetPrimaryFiremode()] == "burst") then
        if ( self:GetNWInt("ShotCount")  >= self.Primary.BurstAmount ) then
            -- Prevents firing if burst has been completed
            return false
        end
    end

    if ( self.Weapon:Clip1() <= 0 ) then 
        -- Prevents firing if there is no ammo
		self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.2 )
        --self:Reload()
        return false  
    end

	return true

end

--[[---------------------------------------------------------
   Name: SWEP:SecondaryAttack( )
   Desc: +attack2 has been pressed
---------------------------------------------------------]]--
function SWEP:SecondaryAttack()

	-- Make sure we can shoot first
	if ( !self:CanSecondaryAttack() ) then return end

	-- Play shoot sound
	self.Weapon:EmitSound("Weapon_Shotgun.Single")
	
	-- Shoot 9 bullets, 150 damage, 0.75 aimcone
	self:ShootBullet( 150, 9, 0.2 )
	
	-- Remove 1 bullet from our clip
	self:TakeSecondaryAmmo( 1 )
	
	-- Punch the player's view
	self.Owner:ViewPunch( Angle( -10, 0, 0 ) )

end

--[[---------------------------------------------------------
   Name: SWEP:CanSecondaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------]]--
function SWEP:CanSecondaryAttack()

    if !self.Secondary.Active then return false end

	if ( self.Weapon:Clip2() <= 0 ) then
	
		self.Weapon:EmitSound( "Weapon_Pistol.Empty" )
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 )
		return false
		
	end

	return true

end