-- =========================
-- SEPGP BIDS LOGIC (NO UI)
-- =========================

sepgp.bids = sepgp.bids or {}
local bids_blacklist = {}
local running_bid = false

-- keywords
local lootBid = {}
lootBid.ms = {"(%+)", "(ms)", "(need)"}
lootBid.os = {"(%-)", "(os)", "(greed)"}

-- =========================
-- CLEAR BIDS
-- =========================
function sepgp:clearBids(reset)
  if reset ~= nil then
    self:debugPrint("Clearing old bids")
  end

  sepgp.bid_item = {}
  sepgp.bids = {}
  bids_blacklist = {}
  running_bid = false

  if self:IsEventScheduled("shootyepgpBidTimeout") then
    self:CancelScheduledEvent("shootyepgpBidTimeout")
  end

  -- hide frame if exists
  if sepgp_bids_frame then
    sepgp_bids_frame:Hide()
  end
end

-- =========================
-- CAPTURE BID FROM CHAT
-- =========================
function sepgp:captureBid(text, sender)
  if not running_bid then return end
  if not (IsRaidLeader() or self:lootMaster()) then return end
  if not sepgp.bid_item or not sepgp.bid_item.link then return end
  if bids_blacklist[sender] then return end
  if not self:inRaid(sender) then return end

  local lowtext = string.lower(text)
  local mskw_found, oskw_found

  for _, f in ipairs(lootBid.ms) do
    if string.find(lowtext, f) then
      mskw_found = true
      break
    end
  end

  for _, f in ipairs(lootBid.os) do
    if string.find(lowtext, f) then
      oskw_found = true
      break
    end
  end

  if not (mskw_found or oskw_found) then return end

  for i = 1, GetNumGuildMembers() do
    local name, rank, _, _, class, _, note, officernote = GetGuildRosterInfo(i)
    if name == sender then
      rank = self:parseRank(name, officernote) or rank
      local spec = mskw_found and "MS" or "OS"
      local rank_idx = self:rankPrio_index(rank, spec) or 1000

      local ep = self:get_ep_v3(name, officernote) or 0
      local gp = self:get_gp_v3(name, officernote) or sepgp.VARS.basegp
      local main_name

      if sepgp_altspool then
        local main, _, _, main_offnote = self:parseAlt(name, officernote)
        if main then
          ep = self:get_ep_v3(main, main_offnote) or 0
          gp = self:get_gp_v3(main, main_offnote) or sepgp.VARS.basegp
          main_name = main
        end
      end

      bids_blacklist[sender] = true

      table.insert(sepgp.bids, {
        name,
        class,
        rank,
        spec,
        rank_idx,
        ep,
        (gp > 0 and ep / gp or 0),
        main_name
      })

      -- AUTO OPEN / REFRESH FRAME
      sepgp:showBidsFrame()

      return
    end
  end
end

function sepgp:captureAddonBid(prefix, message, channel, sender)
  if prefix ~= "SEPGP_BID" then return end
  if not running_bid then return end
  if not self:inRaid(sender) then return end
  if bids_blacklist[sender] then return end
  if message ~= "+" and message ~= "-" then return end

  -- traktujemy to jak zwykły bid
  self:captureBid(message, sender)
end

-- =========================
-- START BIDDING (CALLED FROM LOOT CAPTURE)
-- =========================
function sepgp:startBids(itemLink, itemLinkFull, itemName)
  self:clearBids(true)

  sepgp.bid_item = {
    link = itemLink,
    linkFull = itemLinkFull,
    name = itemName,
  }

  running_bid = true

  self:ScheduleEvent("shootyepgpBidTimeout", self.clearBids, 300, self)
  self:debugPrint("Capturing bids for 5 minutes.")
end

-- =========================
-- SHOW / CREATE BIDS FRAME
-- =========================
function sepgp:showBidsFrame()
  if not sepgp_bids_frame then return end

  if not sepgp_bids_frame:IsShown() then
    sepgp_bids_frame:Show()
  end

  if sepgp_bids_frame.Refresh then
    sepgp_bids_frame:Refresh()
  end
end
