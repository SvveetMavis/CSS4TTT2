if SERVER then
    AddCSLuaFile()
end

DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType = "shotgun"

if CLIENT then
   SWEP.PrintName = "SPAS-12"
    SWEP.Slot = 2

    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 54

    SWEP.Icon = "vgui/ttt/icon_spas12_hl2"
end

SWEP.Base = "weapon_tttbase"

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_SHOTGUN
SWEP.spawnType = WEAPON_TYPE_SHOTGUN

SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Damage = 32
SWEP.Primary.Cone = 0.14
SWEP.Primary.Delay = 1.4
SWEP.Primary.ClipSize = 4
SWEP.Primary.ClipMax = 8
SWEP.Primary.DefaultClip = 4
SWEP.Primary.Automatic = true
SWEP.Primary.NumShots = 6
SWEP.Primary.Sound = Sound("Weapon_Shotgun.Single")
SWEP.PrimaryAnim           = ACT_VM_PRIMARYATTACK
SWEP.Primary.Recoil = 16
SWEP.DeploySpeed = 0.7

SWEP.DryFireSound = ")weapons/shotgun/shotgun_empty.wav"

SWEP.AutoSpawnable = true
SWEP.Spawnable = true
SWEP.AmmoEnt = "item_box_buckshot_ttt"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_shotgun.mdl"
SWEP.WorldModel	= "models/weapons/w_shotgun.mdl"
SWEP.idleResetFix = true

SWEP.IronSightsPos = Vector( -8.98, -10.45, 4.4 )
SWEP.IronSightsAng = Vector( -0.9, 0, 0)

---
-- @ignore
function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Reloading")
    self:NetworkVar("Float", 0, "ReloadTimer")
    self:NetworkVar("Float", 1, "ReloadInterruptTimer")

    return BaseClass.SetupDataTables(self)
end

---
-- @ignore
function SWEP:Reload()
    self:StartReload()
end

---
-- @ignore
function SWEP:StartReload()
    if self:GetReloading() then
        return false
    end

    local owner = self:GetOwner()

    if
        not IsValid(owner)
        or self:Clip1() >= self.Primary.ClipSize
        or owner:GetAmmoCount(self.Primary.Ammo) <= 0
    then
        return false
    end

    local now = CurTime()

    self:SetIronsights(false)
    self:SetNextPrimaryFire(now + self.Primary.Delay)

    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)

    local sequenceDuration = self:SequenceDuration()

    self:SetReloadTimer(now + sequenceDuration)
    self:SetReloadInterruptTimer(now + sequenceDuration * 0.4)
    self:SetReloading(true)

    return true
end

---
-- @ignore
function SWEP:PerformReload()
    local owner = self:GetOwner()

    if
        not IsValid(owner)
        or self:Clip1() >= self.Primary.ClipSize
        or owner:GetAmmoCount(self.Primary.Ammo) <= 0
    then
        return
    end

    local now = CurTime()

    -- Prevent normal shooting in between reloads
    self:SetNextPrimaryFire(now + self.Primary.Delay)

    owner:RemoveAmmo(1, self.Primary.Ammo, false)
    self:SetClip1(self:Clip1() + 1)

    owner:DoAnimationEvent(ACT_HL2MP_GESTURE_RELOAD_PISTOL)
    self:SendWeaponAnim(ACT_VM_RELOAD)

    local sequenceDuration = self:SequenceDuration()

    self:SetReloadTimer(now + sequenceDuration)
    self:SetReloadInterruptTimer(now + sequenceDuration * 0.8)
end

---
-- @ignore
function SWEP:FinishReload()
    self:SetReloading(false)

    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

    self:SetReloadTimer(CurTime() + self:SequenceDuration())
end

---
-- @ignore
function SWEP:Think()
    BaseClass.Think(self)

    if not self:GetReloading() then
        return
    end

    local owner = self:GetOwner()

    if
        owner:KeyDown(IN_ATTACK)
        and self:Clip1() >= 1
        and self:GetReloadInterruptTimer() <= CurTime()
    then
        self:FinishReload()
    elseif self:GetReloadTimer() <= CurTime() then
        if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
            self:FinishReload()
        elseif self:Clip1() < self.Primary.ClipSize then
            self:PerformReload()
	    self:EmitSound("Weapon_Shotgun.Reload")
        else
            self:FinishReload()
        end
    end
end

---
-- @ignore
function SWEP:Deploy()
    self:SetReloading(false)
    self:SetReloadTimer(0)
    self:SetReloadInterruptTimer(0)

    return BaseClass.Deploy(self)
end

---
-- The shotgun's headshot damage multiplier is based on distance. The closer it
-- is, the more damage it does. This reinforces the shotgun's role as short
-- range weapon by reducing effectiveness at mid-range, where one could score
-- lucky headshots relatively easily due to the spread.
-- @ignore
function SWEP:GetHeadshotMultiplier(victim, dmginfo)
    local att = dmginfo:GetAttacker()

    if not IsValid(att) then
        return 3
    end

    local dist = victim:GetPos():Distance(att:GetPos())
    local d = math.max(0, dist - 140)

    -- Decay from 2 to 1 slowly as distance increases. Note that this used to be
    -- 3+, but at that time shotgun bullets were treated like in HL2 where half
    -- of them were hull traces that could not headshot.
    return 1 + math.max(0, 1.0 - 0.002 * (d ^ 1.25))
end

---
-- @ignore
function SWEP:SecondaryAttack()
    if self.NoSights or not self.IronSightsPos or self:GetReloading() then
        return
    end

    self:SetIronsights(not self:GetIronsights())
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

hook.Add("TTTPlayerSpeedModifier", "SpasSpeed" , function(ply, _, _, noLag )
    local wep=ply:GetActiveWeapon()
    if wep and IsValid(wep) and wep:GetClass()=="weapon_ttt_spas12" then
      if TTT2 then
        noLag[1] = noLag[1] * 0.7
      else
        return 0.7
      end
    end
end )
