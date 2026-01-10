-- SEPGP Bids Frame Vanilla Safe (SHIFT + CLICK = GIVE LOOT)

if not sepgp then return end

local frame = CreateFrame("Frame", "SEPGP_BidsFrame", UIParent)
sepgp_bids_frame = frame

frame:SetWidth(420)
frame:SetHeight(360)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

tinsert(UISpecialFrames, frame:GetName())

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("TOP", 0, -12)
frame.title:SetText("Zmiana Warty - Rozdawanie Lootu")
frame.help = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.help:SetPoint("TOP", frame.title, "BOTTOM", 0, -6)
frame.help:SetText("|cffffff00Shift + Click|r = Give item and GP")


frame.lines = {}

local function createBidButton(parent, x, y, text, bidData)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetPoint("TOPLEFT", x, y)
  btn:SetWidth(180)
  btn:SetHeight(16)
  btn:EnableMouse(true)

  btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  btn.text:SetAllPoints(btn)
  btn.text:SetJustifyH("LEFT")
  btn.text:SetText(text)

  btn.bidData = bidData

  btn:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    if not IsShiftKeyDown() then return end
    if not (IsRaidLeader() or sepgp:lootMaster()) then return end

    if sepgp.awardLootToBid then
      sepgp:awardLootToBid(self.bidData)
    end
  end)

  return btn
end

function frame:Refresh()
  for i = 1, getn(self.lines) do
    self.lines[i]:Hide()
  end
  self.lines = {}

  if not sepgp.bids then return end

  local msBids = {}
  local osBids = {}

  for i = 1, getn(sepgp.bids) do
    local bid = sepgp.bids[i]
    local name = bid[1]
    local spec = bid[4]
    local pr = bid[7] or 0

    if spec == "MS" then
      tinsert(msBids, bid)
    elseif spec == "OS" then
      tinsert(osBids, bid)
    end
  end

  sort(msBids, function(a, b) return (a[7] or 0) > (b[7] or 0) end)
  sort(osBids, function(a, b) return (a[7] or 0) > (b[7] or 0) end)

  local headerMS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  headerMS:SetPoint("TOPLEFT", 20, -58)
  headerMS:SetText("|cff00ff00MS|r")
  tinsert(self.lines, headerMS)

  local headerOS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  headerOS:SetPoint("TOPRIGHT", -120, -58)
  headerOS:SetText("|cff3399ffOS|r")
  tinsert(self.lines, headerOS)

  local rows = max(getn(msBids), getn(osBids))
  local y = -60

  for i = 1, rows do
    if msBids[i] then
      local text = msBids[i][1] .. "  |  " .. format("%.3f", msBids[i][7] or 0)
      local btn = createBidButton(frame, 20, y, text, msBids[i])
      tinsert(self.lines, btn)
    end

    if osBids[i] then
      local text = osBids[i][1] .. "  |  " .. format("%.3f", osBids[i][7] or 0)
      local btn = createBidButton(frame, 220, y, text, osBids[i])
      tinsert(self.lines, btn)
    end

    y = y - 18
  end
end

function sepgp:showBidsFrame()
  if not (IsRaidLeader() or self:lootMaster()) then return end
  frame:Show()
  frame:Refresh()
  -- Auto resize frame height
local baseHeight = 120      -- title + help + headers
local rowHeight  = 18
local rowsCount  = rows or 0

local newHeight = baseHeight + (rowsCount * rowHeight)

if newHeight < 200 then newHeight = 200 end
if newHeight > 500 then newHeight = 500 end

frame:SetHeight(newHeight)

end