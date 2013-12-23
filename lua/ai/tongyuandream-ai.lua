function SmartAI:useCardDream(card,use)		
	local target
	if #self.friends_noself>0 then
		self:sort(self.friends_noself,"defense")
		target = self.friends_noself[1]
	else
		target = self.enemies[1]
	end
	if target == nil then return end
	use.card = card	
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_card_intention.Dream = -80

sgs.ai_keep_value.Dream = 3.6
sgs.ai_use_value.Dream = 10
sgs.ai_use_priority.Dream = 9.3

sgs.dynamic_value.benefit.Dream = true

function SmartAI:useCardLeaderAttention(card,use)
	if #self.friends_noself == 0 then return end
	use.card = card
	self:sort(self.friends_noself,"defense")
	if use.to then
		use.to:append(self.friends[1])
	end
end



SmartAI.useCardFinalPrize = SmartAI.useCardAmazingGrace
sgs.ai_use_value.FinalPrize = 3
sgs.ai_keep_value.FinalPrize = -1
sgs.ai_use_priority.FinalPrize = 1.2

-- function SmartAI:willUseDios(card)
-- 	if not card then self.room:writeToConsole(debug.traceback()) return false end
-- 	if self.player:containsTrick("dios") then return end
-- 	if self.player:hasSkill("weimu") and card:isBlack() then return end
-- 	if self.room:isProhibited(self.player, self.player, card) then return end

-- 	local function hasDangerousFriend()
-- 		local hashy = false		
-- 		for _, aplayer in ipairs(self.enemies) do
-- 			if aplayer:hasSkill("guanxing") or (aplayer:hasSkill("gongxin") and hashy)
-- 			or aplayer:hasSkill("qiujie") then
-- 				if self:isFriend(aplayer:getNextAlive()) then return true end
-- 			end
-- 		end
-- 		return false
-- 	end

-- 	if self:getFinalRetrial(self.player) == 2 then
-- 	return
-- 	elseif self:getFinalRetrial(self.player) == 1 then
-- 		return true
-- 	elseif not hasDangerousFriend() then
-- 		local players = self.room:getAllPlayers()
-- 		players = sgs.QList2Table(players)

-- 		local friends = 0
-- 		local enemies = 0

-- 		for _,player in ipairs(players) do
-- 			if self:objectiveLevel(player) >= 4 and not player:hasSkill("wuyan")
-- 			  and not (player:hasSkill("weimu") and card:isBlack()) then
-- 				enemies = enemies + 1
-- 			elseif self:isFriend(player) and not player:hasSkill("hongyan") and not player:hasSkill("wuyan")
-- 			  and not (player:hasSkill("weimu") and card:isBlack()) then
-- 				friends = friends + 1
-- 			end
-- 		end

-- 		local ratio

-- 		if friends == 0 then ratio = 999
-- 		else ratio = enemies/friends
-- 		end

-- 		if ratio > 1.5 then
-- 			return true
-- 		end
-- 	end
-- end

function SmartAI:useCardDios(card, use)
	--if self:willUseDios(card) then
		use.card = card
	--end
end

sgs.ai_use_priority.Dios = 0
sgs.dynamic_value.lucky_chance.Dios = true

sgs.ai_keep_value.Dios = -1

sgs.ai_skill_cardask["@helpsign"] = function(self, data, pattern, target)	
	local carduse = nil
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:objectName() == "helpsign" then			
			carduse = card
			break
		end
	end
	if carduse == nil then return "." end
	local damage = data:toDamage()
	local to = damage.to
	if self:isFriend(to) then
		return "$" .. carduse:getId()
	else
		return "."
	end
	return "."
end