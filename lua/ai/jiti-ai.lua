--------------小资---------------
--小资 ：你可以将一张红色的牌当【桃】使用或打出。
local luaxiaozi_skill = {}
luaxiaozi_skill.name = "luaxiaozi"
table.insert(sgs.ai_skills, luaxiaozi_skill)
luaxiaozi_skill.getTurnUseCard = function(self, inclusive)
	local red = nil
	local cards1 = self.player:getCards("he")
	local cards = sgs.QList2Table(cards1)
	self:sortByUseValue(cards)
	for _,card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("ExNihilo") then
			red = card
			break
		end
	end
	if red then
		local suit = red:getSuitString()
		local point = red:getNumberString()
		local id = red:getId()
		local str = string.format("peach:luaxiaozi[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end
end
sgs.ai_view_as.luaxiaozi = function(card, player, card_place, class_name)
	if card:isRed() then
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()
		return string.format("peach:luaxiaozi[%s:%s]=%d", suit, point, id)
	end
end
sgs.luaxiaozi_suit_value = {
	heart = 6,
	diamond = 6,
}
sgs.ai_chaofeng["chenyuan"] = 4
-------------硬拼-----------------
--硬拼：锁定技，你的【闪】始终视为【杀】
--[[local luayingpin_skill = {}
luayingpin_skill.name = "luayingpin"
table.insert(sgs.ai_skills, luayingpin_skill)
luayingpin_skill.getTurnUseCard = function(self, inclusive)
	local spade = nil
	local cards = self.player:getCards("h")
	for _,card in sgs.qlist(cards) do
		if card:objectName() == "jink" then
			spade = card
			break
		end
	end
	if spade then
		local suit = spade:getSuitString()
		local point = spade:getNumberString()
		local id = spade:getId()
		local str = string.format("slash:luayingpin[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end
end
--[[sgs.ai_filterskill_filter["luayingpin"] = function(card, card_place, player)
	if card:objectName() == "jink" then
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()
		return string.format("slash:luayingpin[%s:%s]=%d", suit, point, id)
	end
end]]
-------------早起--------------
--早起，出牌阶段，你可以弃掉三张不同花色的牌，使得下一回合仍是你的回合
local luazaoqi_skill = {}
luazaoqi_skill.name = "luazaoqi"
table.insert(sgs.ai_skills, luazaoqi_skill)
luazaoqi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luazaoqiCard") then return end
	if self.player:getCards("he"):length() < 3 then return end
	local spade, club, heart, diamond
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:getSuit() == sgs.Card_Spade  then spade = true 
		elseif card:getSuit() == sgs.Card_Club  then club = true 
		elseif card:getSuit() == sgs.Card_Heart then heart = true 
		elseif card:getSuit() == sgs.Card_Diamond  then diamond = true 
		end
	end	
	if (spade and club and diamond) or (spade and club and heart) or (spade and heart and diamond) or (heart and club and diamond) then
		if not self:isWeak(self.player) then
			if self.player:hasUsed("Slash") or self.player:hasUsed("Peach") or 
			self.player:getCards("he"):length()>self.player:getHp()+2 or
			self.player:getHandcardNum()>self.player:getHp() then
				return sgs.Card_Parse("#luazaoqiCard:.:")
			end
		end
	end	
end	

sgs.ai_skill_use_func["#luazaoqiCard"] = function(card, use, self)
	local need_cards = {}
	local spade, club, heart, diamond
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade and not spade then spade = true table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Club and not club then club = true table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Heart and not heart then heart = true table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards, card:getId())
		end
	end
	if #need_cards < 3 then return end
	local k={}	
	local acard
	if #need_cards >=4 then
		for _,card in ipairs(need_cards) do
			table.insert(k, card)
			if #k==3 then
				break
			end
		end
		acard = sgs.Card_Parse("#luazaoqiCard:"..table.concat(k, "+")..":")		
	else
		acard = sgs.Card_Parse("#luazaoqiCard:"..table.concat(need_cards, "+")..":")		
	end	
	assert(acard)
	use.card=acard	
end
sgs.ai_use_value.luazaoqiCard = 4
sgs.ai_use_priority.luazaoqiCard = 2.2
-------------护主-------------
--护主：其他源势力角色可以帮你出【闪】
table.insert(sgs.ai_global_flags, "huzhusource")
sgs.ai_skill_invoke["luahuzhu"] = function(self, data)
	local asked = data:toStringList()
	local prompt = asked[2]
	if not self.player:hasFlag("ai_hantong") then
		if self:askForCard("jink", prompt, 1) == "." then return false end
	end	
	if sgs.huzhusource then return false end
		
	local lieges = self.room:getLieges("yuan", self.player)
	-- if lieges:isEmpty() then return false end
	-- local has_friend = false
	-- for _, p in sgs.qlist(lieges) do
	-- 	if self:isFriend(p) then
	-- 		has_friend = true
	-- 		break
	-- 	end
	-- end
	-- return has_friend
	return not lieges:isEmpty()
end
sgs.ai_choicemade_filter.skillInvoke.luahuzhu = function(player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.huzhusource = player
	end
end

function sgs.ai_slash_prohibit.luahuzhu(self, to, card, from)
	if self:isFriend(to) then return false end
	local guojia = self.room:findPlayerBySkillName("tiandu")
	if guojia and guojia:getKingdom() == "yuan" and self:isFriend(to, guojia) then return sgs.ai_slash_prohibit.tiandu(self, guojia, card, from) end
end

sgs.ai_choicemade_filter.cardResponded["@huzhu-jink"] = function(player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		sgs.updateIntention(player, sgs.huzhusource, -80)
		sgs.huzhusource = nil
	elseif sgs.huzhusource then
		local lieges = player:getRoom():getLieges("yuan", sgs.huzhusource)
		if lieges and not lieges:isEmpty() then
			if player:objectName() == lieges:last():objectName() then
				sgs.huzhusource = nil
			end
		end
	end
end
sgs.ai_skill_cardask["@huzhu-jink"] = function(self)
	if not self.room:getLord() then return "." end
	local yuanshu = self.room:findPlayerBySkillName("weidi")
	if not sgs.huzhusource and not yuanshu then sgs.huzhusource = self.room:getLord() end
	if not sgs.huzhusource then return "." end
	if not self:isFriend(sgs.huzhusource) then return "." end
	if self:needBear() then return "." end
	local bgm_zhangfei = self.room:findPlayerBySkillName("dahe")
	if bgm_zhangfei and bgm_zhangfei:isAlive() and sgs.huzhusource:hasFlag("dahe") then
		for _, card in ipairs(self:getCards("Jink")) do
			if card:getSuit() == sgs.Card_Heart then
				return card:getId()
			end
		end
		return "."
	end
	return self:getCardId("Jink") or "."
end
-------------------------爆发------------------------
--爆发：<b>限定技，</b>当你处于濒死状态时，你可以弃掉区域里的所有牌，
--然后体力上限增至4点且体力回满，再摸四张牌，并失去技能【大意】
sgs.ai_skill_invoke.luabaofa = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			n = n + 1
		end
	end
	return n < peaches
end
sgs.ai_chaofeng["wanghao"] = 5
---------------------妹多--------------------
--[[妹多：出牌阶段，你可以弃X张手牌并选择任意名女性角色，令她们各弃一张牌，然后你回复Y点体力
（X为你已损失体力值且最少为2，Y为所选择的女性角色总数且最多为2），每回合限一次]]--
local luameiduo_skill = {}
luameiduo_skill.name = "luameiduo"
table.insert(sgs.ai_skills, luameiduo_skill)
luameiduo_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luameiduoCard") then return nil end
	local x=math.max(2,self.player:getLostHp())
	local cards=sgs.QList2Table(self.player:getHandcards())	
	if #cards<x then return nil end
	local n=0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not(p:isNude()) and p:isFemale() then 
			 n=n+1
			 break
		end
	end
	if n==0 then return nil end	
	return sgs.Card_Parse("#luameiduoCard:.:")
end
sgs.ai_skill_use_func["#luameiduoCard"] = function(card, use, self)
	local x=math.max(2,self.player:getLostHp())
	local cards=sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	--cards=sgs.reverse(cards)
	if #cards<x then return nil end
	--手牌数要够
	local need_cards={}
	for _, c in ipairs(cards) do
		table.insert(need_cards,c:getId())
		if #need_cards==x then
			break
			--需要的手牌数为X
		end
	end
	local targets_friend={}
	--所有友方非空城女性武将名
	local targets_enemy={}
	--所有敌方非空城女性武将名
	local targets={}
	--最终的目标武将名
	local players=sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(players, "hp")
	for _, p in ipairs(players) do
		if not(p:isNude()) and p:isFemale() then 			 
			 if self:isEnemy(p) then
			 	table.insert(targets_enemy,p)
			 else 
			 	table.insert(targets_friend,p)	
			 end		 
		end
	end
	if #targets_enemy==0 and #targets_friend==0 then return nil end
	--若没有女性武将则返回nil
	local wound = self.player:getLostHp()	
	if wound>=2 then
	--已损失体力值大于等于2时
		if #targets_enemy==0 then
			--若敌方没有女性武将则最多只选择2名本方武将即可
			if #targets_friend>2 then
				for k=1,2 do
					--table.insert(targets,targets_friend[k])
					targets[k]=targets_friend[k]
				end
			else
				targets=targets_friend
			end
		elseif #targets_enemy==1 then
			--若敌方只有一名女性武将，则选择她并选择一名本方女性武将
			if #targets_friend ~=0 then			
				targets[1]=targets_enemy[1]			
				targets[2]=targets_friend[1]
			else
				targets=targets_enemy
			end
		else
			targets=targets_enemy
		end
	elseif wound==0 then
		if #targets_enemy==1 then			
			if self.player:getHandcardNum()==self.player:getHp() then 
				return nil 
			else
				targets=targets_enemy
			end
		elseif #targets_enemy==0 then
			return nil
		else
			targets=targets_enemy
		end
	else
		targets=targets_enemy
	end
	--其他的情况都选择敌方武将
	if #targets==0 then return nil end
	--若没有目标则返回nil
	local acard = sgs.Card_Parse("#luameiduoCard:"..table.concat(need_cards, "+")..":")
	assert(acard)
	use.card=acard
	for _,target in ipairs(targets) do
		if use.to then
			use.to:append(target)			
		end
	end	
end
sgs.ai_use_priority.luameiduoCard = 3.2

--------------------随意-----------
--随意：你可以将一张【桃】当【酒】，一张【酒】当【桃】使用或打出
local luasuiyi_skill={}
luasuiyi_skill.name="luasuiyi"
table.insert(sgs.ai_skills,luasuiyi_skill)
luasuiyi_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")	
	cards=sgs.QList2Table(cards)	
	local analeptic_card
	local peach_card
	self:sortByUseValue(cards)
	--cards = sgs.reverse(cards)	
	for _,card in ipairs(cards)  do
		if card:isKindOf("Analeptic") then
			analeptic_card = card
			break
		end
	end
	for _,card in ipairs(cards)  do
		if card:isKindOf("Peach") then
			peach_card = card
			break
		end
	end
	if self.player:getLostHp()>0 then
		if not analeptic_card then return nil end
		local suit = analeptic_card:getSuitString()
		local number = analeptic_card:getNumberString()
		local card_id = analeptic_card:getEffectiveId()
		local card_str = string.format("peach:luasuiyi[%s:%s]=%d", suit, number, card_id)
		local peach = sgs.Card_Parse(card_str)
		assert(peach)		
		return peach
	else
		if not peach_card then return nil end
		if self.player:hasUsed("Analeptic") then return nil end
		local suit = peach_card:getSuitString()
		local number = peach_card:getNumberString()
		local card_id = peach_card:getEffectiveId()
		local card_str = string.format("analeptic:luasuiyi[%s:%s]=%d", suit, number, card_id)
		local analeptic = sgs.Card_Parse(card_str)
		assert(analeptic)		
		return analeptic
	end
		
end

sgs.ai_view_as.luasuiyi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceEquip then
		if card:isKindOf("Peach") then
			return string.format("analeptic:luasuiyi[%s:%s]=%d", suit, number, card_id)
		elseif card:isKindOf("Analeptic") then
			return string.format("peach:luasuiyi[%s:%s]=%d", suit, number, card_id)
		end
	end
end

sgs.luasuiyi_keep_value = {
	Peach = 6,
	Analeptic = 6,	
}
------------------膜拜-------------
--膜拜：其他源势力角色可以在其出牌阶段给你一张【桃】或【酒】
local luamobaiVS_skill = {}
luamobaiVS_skill.name = "luamobaiVS"
table.insert(sgs.ai_skills, luamobaiVS_skill)
luamobaiVS_skill.getTurnUseCard = function(self)
	if self.player:hasFlag("forbinmobai") then return nil end
	if self.player:getKingdom() ~= "yuan" then return nil end		
	local card	
	local cards = self.player:getHandcards()
	for _,acard in sgs.qlist(cards) do
		if acard:isKindOf("Peach") or acard:isKindOf("Analeptic") then
			card = acard
			break
		end
	end	
	if not card then return nil end
	return sgs.Card_Parse("#luamobaiCard:.:")	
end
sgs.ai_skill_use_func["#luamobaiCard"] = function(card, use, self)	
	local cards = self.player:getHandcards()
	local peach={}
	local analeptic={}	 --统计桃的数量和酒桃的总数
	for _,card in sgs.qlist(cards) do
		if card:isKindOf("Peach") then
			table.insert(peach,card)
			table.insert(analeptic,card)
		elseif card:isKindOf("Analeptic")  then
			table.insert(analeptic,card)
		end				
	end		
	if #analeptic==0 then return "." end--若总数为0则不发动
	local lord = self.room:getLord()--若身份为忠臣且主公很虚弱时，发动
	if lord:hasLordSkill("luamobai") and self.role == "loyalist" and self:isWeak(lord) then 
		use.card = sgs.Card_Parse("#luamobaiCard:" .. analeptic[1]:getId()..":")
		if use.to then
			use.to:append(lord)			
		end
	end
	--若自身虚弱且桃的数量小于2，且没有酒时不发动
	if self:isWeak(self.player) and #peach<=1 and #peach == #analeptic then return "." end
	self:sortByKeepValue(analeptic)	
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("luamobai") then
			if not friend:hasFlag("mobaiInvoked") then
				if not friend:hasSkill("manjuan") then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --膜拜己方
		use.card = sgs.Card_Parse("#luamobaiCard:" .. analeptic[1]:getId()..":")
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])			
		end
	elseif self:getCardsNum("Slash", self.player, "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("luamobai") then
				if not enemy:hasFlag("luamobaiInvoked") then
					if not enemy:hasSkill("manjuan") then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not enemy:hasSkills("tuntian+zaoxian") then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:hasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:hasUsed("XianzhenCard") then
				flag = true
			elseif self.player:hasSkill("luatiaokan") and not self.player:hasUsed("luatiaokanCard") then
				flag = true 
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > analeptic[1]:getNumber() then --可以保证拼点成功
					self:sort(targets, "defense")
					targets = sgs.reverse(targets) 
					for _,enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
							use.card = sgs.Card_Parse("#luamobaiCard:" .. analeptic[1]:getId()..":")
							enemy:setFlags("AI_HuangtianPindian")
							if use.to then
								use.to:append(enemy)
							end
							break
						end
					end
				end
			end
		end
	end    
end
sgs.ai_chaofeng["yexuefeng"] = 3
sgs.ai_card_intention.luamobaiCard = -80

sgs.ai_use_priority.luamobaiCard = 4
sgs.ai_use_value.luamobaiCard = 4.5
--------------卖萌-----------
--卖萌：出牌阶段，你可以弃置两张红色牌,然后你回复一点体力
local luamaimeng_skill = {}
luamaimeng_skill.name = "luamaimeng"
table.insert(sgs.ai_skills, luamaimeng_skill)
luamaimeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getLostHp()==0 then return nil end	
	if self.player:getCards("he"):length() < 2 then return nil end
	local n=0
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isRed() and not card:isKindOf("Peach") then 
			n=n+1
		end
	end
	if n<2 then return nil end		
	return sgs.Card_Parse("#luamaimengCard:.:")	
end	

sgs.ai_skill_use_func["#luamaimengCard"] = function(card, use, self)
	local need_cards = {}	
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isRed() and not card:isKindOf("Peach") then 
			table.insert(need_cards, card:getId())
			if 	#need_cards == 2 then
				break
			end
		end
	end
	if #need_cards < 2 then return end		
	local acard	
	acard = sgs.Card_Parse("#luamaimengCard:"..table.concat(need_cards, "+")..":")	
	assert(acard)
	use.card=acard	
end

sgs.ai_use_priority.luamaimengCard = 4

-------------花痴------------------
--花痴：当男性角色每受到一点伤害后，你可以展示其一张手牌，若为红色，则其弃置之并恢复一点体力
sgs.ai_skill_invoke["luahuachi"] = function(self, data)
	local damage = data:toDamage()
	local victim=damage.to
	if not victim:isMale() then return false end
	if self.role == "renegade" and (not victim:isLord())  and 
			sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] then
		return false
	end
	return self:isFriend(victim)
end
------------调侃-----------
--调侃：出牌阶段，你可以与一名其他角色进行拼点，若你赢，则该角色的武将牌翻面，每回合限一次
local luatiaokan_skill = {}
luatiaokan_skill.name = "luatiaokan"
table.insert(sgs.ai_skills, luatiaokan_skill)
luatiaokan_skill.getTurnUseCard = function(self, inclusive)
	if self:needBear() then return end
	if self.player:hasUsed("#luatiaokanCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#luatiaokanCard:.:") 	
end	

sgs.ai_skill_use_func["#luatiaokanCard"] = function(card, use, self)
	local cards=self.player:getHandcards()
	cards=sgs.QList2Table(cards)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	self:sort(self.enemies, "defense")
	self.enemies=sgs.reverse(self.enemies)
	self:sort(self.friends_noself,"defense")
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp()  then
			if max_point >= 10 then
				use.card = sgs.Card_Parse("#luatiaokanCard:" .. max_card:getId()..":")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end	
	for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and 
				not enemy:isKongcheng() and enemy:faceUp() then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					use.card = sgs.Card_Parse("#luatiaokanCard:" .. max_card:getId()..":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and 
			not enemy:isKongcheng() and enemy:faceUp() then
			if max_point >= 10 then
				use.card = sgs.Card_Parse("#luatiaokanCard:" .. max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end			
end

sgs.ai_use_priority.luatiaokanCard = 4
sgs.ai_chaofeng["houyuxing"] = 6
------------大腿--------------
--大腿：当有角色进入濒死状态时，你可以进行一次判定，若结果为红色，其回复一点体力
sgs.ai_skill_invoke["luadatui"] = function(self, data)
	local dying = data:toDying()
	if self.role == "renegade" and not (dying.who:isLord() or dying.who:objectName() == self.player:objectName()) and 
			(sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] or 
				self.room:getCurrent():objectName() == self.player:objectName()) then
		return false
	end
	return self:isFriend(dying.who) or dying.who:objectName() == self.player:objectName()	
end
------------何必---------------
--何必：在一名角色的判定牌生效前，你可以打出一张红色牌替换之。
sgs.ai_skill_invoke["luahebi"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return false end
	local cards = {}
	local heart = {}
	local diamond = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isRed() then
			table.insert(cards, card)
			if card:getSuit() == sgs.Card_Heart then
				table.insert(heart, card)
			else
				table.insert(diamond, card)
			end
		end
	end
	if #cards == 0 then return false end
	self:sortByUseValue(cards)
	local who=judge.who
	local reason = judge.reason
	if reason=="luadatui" or "TYdatui" then
		if self:isFriend(who) then
			if not judge:isGood() then
				return true	
			elseif (judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo")) then
				return true
			end 				
		elseif judge:isGood() then
			if (judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo")) then
				return true
			end			
		end			
	elseif reason=="luoshen" then
		if self:isEnemy(who) then
			if judge:isGood() then
				return true
			elseif judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo") then
				return true
			end
		elseif not judge:isGood() then
			if judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo") then
				return true
			end			
		end		
	elseif reason == "indulgence" then
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or 
			judge.card:isKindOf("ExNihilo")) and #heart ~= 0 then
			return true
		elseif self:isEnemy(who) and #diamond ~= 0 then
			return judge:isGood()		
		end
	elseif reason == "ganglie" then
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo")) then
			return true
		elseif self:isEnemy(who) and #heart ~= 0 then
			return judge:isGood()
		end		
	end 
	if self:isFriend(who) and not judge:isGood() then
	 	return true 
	elseif self:isEnemy(who) then
		return judge:isGood() 
	end
	return false
end
sgs.ai_skill_cardask["@luahebi"]=function(self, data, pattern, target, target2)
	local judge = data:toJudge()
	local all_cards = sgs.QList2Table(self.player:getCards("he"))
	if #all_cards==0 then return "." end
	local cards = {}
	local heart = {}
	local diamond = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isRed() then
			table.insert(cards, card)
			if card:getSuit() == sgs.Card_Heart then
				table.insert(heart, card)
			else
				table.insert(diamond, card)
			end
		end
	end
	if #cards == 0 then return "." end
	self:sortByUseValue(cards)
	local who=judge.who
	local reason = judge.reason
	local card = cards[1]
	--assert(card)
	if reason=="luadatui" or "TYdatui" then
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo"))then
			return card:toString()		
		else
			return "."
		end	
	elseif reason=="luoshen" then
		if self:isEnemy(who) and judge:isGood() then
			return card:toString()
		elseif self:isFriend(who) and not judge:isGood() and (judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo")) then
			return card:toString()
		else
			return "."
		end
	elseif reason == "indulgence" then
		--local card=nil
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or 
			judge.card:isKindOf("ExNihilo")) and #heart~= 0 then
			return heart[1]:toString()						
		elseif self:isEnemy(who) and judge:isGood() and #diamond ~= 0 then
			return diamond[1]:toString()			
		else
			return "."
		end
	elseif reason == "ganglie" then		
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") 
			or judge.card:isKindOf("ExNihilo")) and #diamond ~= 0 then
			return diamond[1]:toString()			
		elseif self:isEnemy(who) and judge:isGood() and #heart~= 0 then
			return heart[1]:toString()			
		else
			return "."
		end
	end
	return card:toString() or "."
end
--------协作------------
sgs.ai_skill_playerchosen["luaxiezuo"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	return nil
end
sgs.luahebi_suit_value = {
	heart = 6,
	diamond = 6
}
sgs.ai_chaofeng["zhengmin"] = 5
------------飞盘---------------
--飞盘：你可以获得其他角色进入弃牌堆点数等于你当前体力值两倍的牌
sgs.ai_skill_askforag.luafeipan = function(self, card_ids)
	return -1
end
-----------憋屈----------------
--憋屈：每当你使用的【杀】被【闪】抵消时，你可以回复一点体力或者摸两张牌
sgs.ai_skill_choice["luabiequ"] = function(self, choices, data)
	if self.player:isWounded() then
		local hp = self.player:getHp()
		local count = self.player:getHandcardNum()
		if hp >= count + 2 then
			return "draw"
		else
			return "recover"
		end
	end
	return "draw"
end
-----------借牌------------
sgs.ai_skill_invoke["luajiepai"] = function(self, data)	
	if self.player:getLostHp() >1 then return false end
	local hp = self.player:getHp()
	local count = self.player:getHandcardNum()
	local cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards) do
		if card:isKindOf("Peach") and self.player:isWounded() then
			return false
		end
	end
	return hp >= count-2
end
sgs.ai_skill_playerchosen["luajiepai"] = function(self, targets)
	local target
	local n=0
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			if p:getHandcardNum()>n then
				n=p:getHandcardNum()
				target=p				
			end
		end		
	end
	if n>=2 then
		return target
	end
	return false
end
------------睡神------------
--睡神：回合开始阶段，你可以回复一点体力或者摸两张牌
sgs.ai_skill_choice["luashuishen"] = function(self, choices, data)
	if self.player:isWounded() then
		local cards=self.player:getCards("j")
		for _,card in sgs.qlist(cards) do 
			if card:isKindOf("indulgence") then
				return "recover"				
			end
		end
		local hp = self.player:getHp()
		local count = self.player:getHandcardNum()
		if hp >= count + 2 then
			return "draw"
		else
			return "recover"
		end
	end
	return "draw"
end
---------------为民--------------
--为民：当有其他角色进入濒死阶段时，你可以自减一点体力使其恢复一点体力
sgs.ai_skill_invoke["luaweimin"] = function(self, data)
	local dying = data:toDying()
	local target = dying.who
	local peach = 0
	if self:isEnemy(target) then return false end
	if self.player:getHp() <=0 then return false end
	if self.player:getHp() == 1 then
		if self.role == "loyalist" and target:isLord() then return true end
		local cards = self.player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
				peach = peach + 1
			end
		end
		if peach <= 1-self.player:getHp() then return false end
		return true
	end
	return true
end
sgs.ai_chaofeng["libingxuan"] = 4
---------------低调-------------
--低调：每当其他角色受到伤害时，你可以自减一点体力使其所受伤害减少一点，若如此做，则你摸一张牌
sgs.ai_skill_invoke["luadidiao"] = function(self, data)
	local damage = data:toDamage()		
	local victim = damage.to
	local peach = 0
	if self:isEnemy(victim) then return false end
	if self.player:getHp() <=0 then return false end
	if self:isFriend(victim) and self:isWeak(victim) then 
		if self.player:getHp() == 1 then
			if self.role == "loyalist" and victim:isLord() and victim:getHp()<=2 then return true end
			local cards = self.player:getHandcards()
			for _,card in sgs.qlist(cards) do
				if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
					peach = peach + 1
				end				
			end
			if peach == 0 then return false end
			return true
		end	
		return true
	end
	if self.player:getLostHp() + self.player:getHandcardNum() >4 then return false end
	return false
end
--------------辅佐----------------
--辅佐：当有角色失去了体力或者受到了伤害时，你可以弃掉两张牌使其回复一点体力
sgs.ai_skill_invoke["luafuzuo"] = function(self, data)
	local damage = data:toDamage()
	local victim = damage.to
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)	
	if #cards<2 then return false end	
	self:sortByUseValue(cards) 
	--cards=sgs.reverse(cards)
	local players = self.room:getAlivePlayers()		
	if self:isEnemy(victim) then			
		return false 
	end
	if self:isFriend(victim) and self:isWeak(victim) then 
		if #cards==2  or #cards==3 then --若友方处于虚弱状态且总牌数为2张或3张时
			local peach = 0
			local analeptic = 0
			for _,card in ipairs(cards) do
				if card:isKindOf("Peach") then 
					peach = peach + 1
					analeptic = analeptic + 1
				elseif card:isKindOf("Analeptic") or card:isKindOf("Slash") then
					analeptic = analeptic + 1
				end
			end			
			if victim:objectName() == self.player:objectName() and self.player:getHp()<=0 
				and analeptic +self.player:getHp() > 0 then
				return false 
			end
			if peach == 0 then	--若没桃就发动，否则不发动				
				return true 
			end				
			return false
		end			
		return true--总牌数大于3张时发动
	end
	if #cards > self.player:getHp()+2 then --友方不虚弱时若自己总牌数大于当前体力值就发动		
		return true 
	end			
	return false	
end
--------------海量-----------------
--海量：你可以把【杀】当【酒】使用或打出
local luahailiang_skill = {}
luahailiang_skill.name = "luahailiang"
table.insert(sgs.ai_skills, luahailiang_skill)
luahailiang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("Analeptic") or self.player:isKongcheng() then return nil end
	local slash = nil
	local cards1 = self.player:getHandcards()
	local cards = sgs.QList2Table(cards1)
	self:sortByUseValue(cards)
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			slash = card
			break
		end
	end
	if slash then
		local suit = slash:getSuitString()
		local point = slash:getNumberString()
		local id = slash:getId()
		local str = string.format("analeptic:luahailiang[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end
end
sgs.ai_view_as.luahailiang = function(card, player, card_place, class_name)
	if card:isKindOf("Slash") then
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()
		return string.format("analeptic:luahailiang[%s:%s]=%d", suit, point, id)
	end
end
-------------气盛------------------
--气盛：出牌阶段，你可以将两张相同类型的牌当【决斗】使用
local luaqisheng_skill={}
luaqisheng_skill.name="luaqisheng"
table.insert(sgs.ai_skills,luaqisheng_skill)
luaqisheng_skill.getTurnUseCard=function(self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getCards("he")
		local same_type=false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo") or fcard:isKindOf("Duel")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getTypeId() == first_card:getTypeId() and 
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo") or scard:isKindOf("Duel")) then						
						second_card = scard						
						local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
						duel:addSubcard(first_card)
						duel:addSubcard(second_card)						
						local dummy_use = {isDummy = true}
						self:useTrickCard(duel, dummy_use)
						if dummy_use.card then second_found = true break end						
					end
				end
				if first_found and second_found then break end
			end
		end
	end
	if first_found and second_found then
		local first_id, second_id =  first_card:getId(), second_card:getId()
		local suit="no_suit"
		if first_card:isBlack() == second_card:isBlack() then suit = first_card:getSuitString() end
		local card_str
		if sgs.Sanguosha:getVersion() <= "20121221" then
			card_str = ("duel:luaqisheng[%s:%s]=%d+%d"):format(suit, 0, first_id, second_id)
		else
			card_str = string.format("duel:luaqisheng[%s:%s]=%d+%d", suit, point, first_id, second_id)
		end
		local duel1 = sgs.Card_Parse(card_str)
		assert(duel1)			
		return duel1
	end
end
-----------暴力----------
--暴力：每当你将对一名其他角色造成伤害时，你可以自减与该伤害等量的体力，然后你对该角色造成的伤害加倍
sgs.ai_skill_invoke["luabaoli"] = function(self, data)
	local damage = data:toDamage()		
	local victim = damage.to
	local x = damage.damage	
	local hp = self.player:getHp()
	local peach = 0
	local analeptic = 0
	if self:isFriend(victim) then return false end
	if hp < x then return false end
	if self:isEnemy(victim)  and not victim:hasArmorEffect("SilverLion") then
		if self.role =="rebel" and victim:isLord() and victim:getHp() <=2 then return true end	
		local cards = self.player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:isKindOf("Peach") then
				peach = peach + 1
				analeptic = analeptic + 1
			elseif card:isKindOf("Analeptic")  then
				analeptic = analeptic + 1
			end				
		end		
		if hp == x then
			if analeptic < x-hp+1 then return false end
			return true
		elseif 	2*peach+hp-x-self.player:getHandcardNum()+2>=0 then
			return true
		end
		return false
	end	
end
-----------求援-----------
--求援：其他源势力雄角色每造成或受到一次伤害时可以进行一次判定，若结果为方片，则你回复一点体力
sgs.ai_skill_playerchosen["luaqiuyuan"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	return nil
end
-----------淡定----------
--淡定：出牌阶段，你可以弃掉两张手牌视为对你攻击范围内一名其他角色使用一张【杀】，此【杀】不计入回合内使用次数限制，每回合限一次
local luadanding_skill = {}
luadanding_skill.name = "luadanding"
table.insert(sgs.ai_skills, luadanding_skill)
luadanding_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luadandingCard") then return nil end	
	local cards=sgs.QList2Table(self.player:getHandcards())	
	if #cards<2 then return nil end	
	if self:isWeak(self.player) then return nil end	
	return sgs.Card_Parse("#luadandingCard:.:")
end
sgs.ai_skill_use_func["#luadandingCard"] = function(card, use, self)	
	local cards=sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	--cards=sgs.reverse(cards)
	if #cards<2 then return nil end	
	local need_cards={}
	for _, c in ipairs(cards) do
		table.insert(need_cards,c:getId())
		if #need_cards==2 then
			break			
		end
	end	
	local targets={}
	if #self.enemies == 0 then return end	
	self:sort(self.enemies, "hp")
	for _,enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() then
			table.insert(targets,enemy)			
		end
	end
	if #targets == 0 then return nil end
	local target=targets[1]	
	local acard = sgs.Card_Parse("#luadandingCard:"..table.concat(need_cards, "+")..":")
	assert(acard)
	use.card=acard
	if target then
		if use.to then
			use.to:append(target)			
		end
	end	
end
sgs.ai_use_priority.luadandingCard = 2.3
-------------节俭---------------
--节俭：你可以获得其他角色进入弃牌堆的装备牌。
sgs.ai_skill_askforag.luajiejian = function(self, card_ids)
	return -1
end
------------因霸--------------
--因霸：你可以将一张装备牌当如下牌使用：武器牌当【五谷丰登】，防具牌当【桃园结义】，+1马当【南蛮入侵】，-1马当【万箭齐发】
local luayinba_skill={}
luayinba_skill.name="luayinba"
table.insert(sgs.ai_skills,luayinba_skill)
luayinba_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards)
	cards=sgs.reverse(cards)
	if #cards == 0 then return nil end
	for _, card in ipairs(cards) do
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()
		if card:isKindOf("Weapon") then
			return sgs.Card_Parse(string.format("amazing_grace:luayinba[%s:%s]=%d", suit, point, id))
		elseif card:isKindOf("Armor") then
			return sgs.Card_Parse(string.format("god_salvation:luayinba[%s:%s]=%d", suit, point, id))
		elseif card:isKindOf("DefensiveHorse") then
			return sgs.Card_Parse(string.format("savage_assault:luayinba[%s:%s]=%d", suit, point, id))
		elseif card:isKindOf("OffensiveHorse") then
			return sgs.Card_Parse(string.format("archery_attack:luayinba[%s:%s]=%d", suit, point, id))			
		end		 			
	end
end
-----------有煤--------------
--有煤：锁定技，你的黑桃牌均视为梅花牌
--[[sgs.ai_filterskill_filter["luayoumei"] = function(card, card_place, player)
	if card:getSuit() == sgs.Card_Spade then
		local name = card:objectName()		
		local point = card:getNumberString()
		local id = card:getEffectiveId()
		return string.format("%s:luayoumei[club:%s]=%d", name, point, id)		
	end
end]]
------------钱哥-----------------
--钱哥：你可以将一张梅花手牌当【过河拆桥】使用
local luaqiange_skill = {}
luaqiange_skill.name = "luaqiange"
table.insert(sgs.ai_skills, luaqiange_skill)
luaqiange_skill.getTurnUseCard = function(self, inclusive)
	local club = nil
	local cards = self.player:getCards("h")
	for _,card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Club then
			club = card
			break
		end
	end
	if club then
		local suit = club:getSuitString()
		local point = club:getNumberString()
		local id = club:getId()
		local str = string.format("dismantlement:luaqiange[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end
end
-------------学霸----------------
--学霸：出牌阶段，你可以弃一张手牌，从而永久获得场上存活角色的一项武将技能（不能是主公技、限定技和觉醒技），整局游戏限三次。
local luaxueba_skill = {}
luaxueba_skill.name = "luaxueba"
table.insert(sgs.ai_skills, luaxueba_skill)
luaxueba_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@xueba")==0 then return nil end
	if self.player:hasUsed("#luaxuebaCard") then return nil end	
	if self.player:isKongcheng() then return nil end		
	return sgs.Card_Parse("#luaxuebaCard:.:")
end
sgs.ai_skill_use_func["#luaxuebaCard"] = function(card, use, self)	
	local shoupais=sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(shoupais)
	--shoupais=sgs.reverse(shoupais)
	if #shoupais == 0 then return nil end
	local acard = sgs.Card_Parse("#luaxuebaCard:" .. shoupais[1]:getId()..":")
	use.card = acard
	local flag=0--这货只是用来确定是否跳出了最内层循环		
	local target=nil
	local sks = {}---定义技能表	
	local players = self.room:getOtherPlayers(self.player)
	for _,player in sgs.qlist(players) do
		if player:isAlive() then
			--if not (player:getGeneralName() == "shenzhugeliang" or player:getGeneralName() == "zuoci") then
			--获取场上所有角色的技能表（除去玩家已获得的技能）
				for _,ski in sgs.qlist(player:getVisibleSkillList()) do
					if not ski:isLordSkill() then
						if ski:getFrequency() ~= sgs.Skill_Limited then
							if ski:getFrequency() ~= sgs.Skill_Wake then
								if not (ski:objectName() == "huoshou" ) then
									if not self.player:hasSkill(ski:objectName()) then
										table.insert(sks, ski:objectName())								
									end	
								end						
							end
						end
					end
				end
			--end
		end
	end		
	if #sks == 0 then return nil end
	local choices = table.concat(sks, "+")
	if self.player:getHp() <= 1 and choices:matchOne("buqu") then
		target = self.room:findPlayerBySkillName("buqu")
		if target:isAlive() then
			if use.to then			
				use.to:append(target)
				return			
			end
		end					
	end
	if self.player:getHp() == 1 then									
		for _, askill in ipairs(("wuhun|duanchang|jijiu|longhun|jiushi|jiuchi|buyi|huilei|dushi|buqu|zhuiyi|jincui"):split("|")) do
			if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
				target = self.room:findPlayerBySkillName(askill)
				if target:isAlive() then
					if use.to then			
						use.to:append(target)
						return			
					end
				end		 
			end
		end					
	end
						
	if choices:matchOne("guixin") and (not self:isWeak() or self:getAllPeachNum() > 0) and self.room:alivePlayerCount() > 3 then 
		target = self.room:findPlayerBySkillName("guixin")
		if target:isAlive() then
			if use.to then			
				use.to:append(target)
				return			
			end
		end	 
	end
	
	for _, askill in ipairs(("luasuanfa|yiji|fankui|jieming|neoganglie|ganglie|enyuan|fangzhu|nosenyuan|langgu"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) and (self.player:getHp() > 1 or self:getAllPeachNum() > 0) then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end		 
		end
	end				

	if self.player:getHandcardNum()==1 then
		if choices:matchOne("kongcheng") then 
			target = self.room:findPlayerBySkillName("kongcheng")
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end		 
		end
	end
	
								
	if self.player:hasArmorEffect("Vine") or self.player:getMark("@gale") > 0 then
		if choices:matchOne("shuiyong") then 
			target = self.room:findPlayerBySkillName("shuiyong")
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end		 
		end
	end								

	if self.player:getCards("e"):length() > 1 then
		for _, askill in ipairs(sgs.lose_equip_skill:split("|")) do
			if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
				target = self.room:findPlayerBySkillName(askill)
				if target:isAlive() then
					if use.to then			
						use.to:append(target)
						return			
					end
				end	 
			end
		end					
	end

	for _, askill in ipairs(("luaxiaozi|luadatui|luakaoshen|luamaimeng|luawugu|luaqiansao|luaciba|luayinren|luashuishen|lualaoshi|"..
		"luabiequ|luachijiu|luaxuzong|luaqiangge|rende|noswuyan|luaweiwu|weimu|wuyan|guzheng|luoying|luafeipan|luajiejian|kanpo|liuli|beige|qingguo|"..
		"mingzhe|xiangle|feiying|longdan|luashuaiqi|tuxi|haoshi|kongcheng|guanxing|zhiheng|qice|lijian|neofanjian|luashanyan|shuijian|shelie|luoshen|" ..
		"biyue|luahuijia|yingzi|qingnang|luashicheng|mingce|fanjian|duyi|mizhao|duanliang|guose|" ..
		"baobian|ganlu|moukui|liegong|mengjin|tieji|luatiaokan|wushuang|fuhun|qianxi|" ..
		"lirang|lieren|pojun|bawang|qixi|luaqiange|jizhi|luaduoshi|paoxiao|luadanding|" ..									
		"luanji|zhijian|shuangxiong|luaqisheng|xinzhan|zhenwei|jieyuan|duanbing|fenxun|guidao|luahebi|guicai|luahebi|zhenlie|wansha|" ..
		"lianpo|yicong|nosshangshi|shangshi|luaxuewei|lianying|tianyi|xianzhen|keji|huoji|xiaoji|" ..
		"xuanfeng|nosxuanfeng|jiushi|dangxian|qicai|luazaoqi|luaweimeng|" ..
		"xingshang|weiwudi_guixin|shenfen"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end		 
		end
	end	

	for _, askill in ipairs(("yizhong|bazhen"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) and not self.player:getArmor() then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end		 
		end
	end								
	for _, askill in ipairs(("cangni|jushou|kuiwei|lihun"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) and not self.player:faceUp() then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end	 
		end
	end				

	for _, askill in ipairs(("huangen|mingshi|jianxiong|tanlan|jiang|qianxun|tianxiang|danlao|juxiang|luaguaixiao|lualaoshi|zhichi|yicong|wusheng|wushuang|" ..
	"leiji|guhuo|nosshangshi|shangshi|zhiyu|lirang|jijiu|luahailiang|buyi|lianying|tianming|jieyuan|mingshi|xiaoguo|shushen|shuiyong|" ..
	"tiandu|zhenlie|lualuji"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end	
		end
	end											

	for _, askill in ipairs(("xingshang|weidi|chizhong|jilei|sijian|badao|jizhi|anxian|wuhun|hongyan|buqu|dushi|zhuiyi|huilei"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end	
		end
	end				

	for _, askill in ipairs(("jincui|beifa|yanzheng|xiaoji|xuanfeng|nosxuanfeng|longhun|jiushi|jiuchi|nosjiefan|kuanggu|lianpo"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end	 
		end
	end				
	
	for _, askill in ipairs(("tongxin|gongmou|weiwudi_guixin|wuling|kuangbao"):split("|")) do
		if choices:matchOne(askill) and not self.player:hasSkill(askill) then 
			target = self.room:findPlayerBySkillName(askill)
			if target:isAlive() then
				if use.to then			
					use.to:append(target)
					return			
				end
			end	
		end
	end	
end
sgs.ai_skill_choice["luaxueba"] = function(self, choices, data)
	local str = choices
	for _, askill in ipairs(("yiji|fankui|jieming|neoganglie|ganglie|enyuan|fangzhu|nosenyuan|langgu|"..
		"luaxiaozi|luadatui|luakaoshen|luamaimeng|luawugu|luaqiansao|luaciba|luayinren|luashuishen|lualaoshi|"..
		"luabiequ|luachijiu|luaxuzong|luaqiangge|jijiu|rende|noswuyan|luaweiwu|weimu|wuyan|guzheng|luoying|luafeipan|luajiejian|kanpo|liuli|beige|qingguo|"..
		"mingzhe|xiangle|feiying|longdan|luashuaiqi|tuxi|haoshi|guanxing|zhiheng|qice|lijian|neofanjian|luashanyan|shuijian|shelie|luoshen|" ..
		"biyue|luahuijia|yingzi|qingnang|luashicheng|mingce|fanjian|duyi|mizhao|duanliang|guose|" ..
		"baobian|ganlu|moukui|liegong|mengjin|tieji|longhun|luatiaokan|wushuang|fuhun|qianxi|" ..
		"lirang|lieren|pojun|bawang|qixi|luaqiange|jizhi|luaduoshi|paoxiao|luadanding|" ..									
		"luanji|zhijian|shuangxiong|luaqisheng|xinzhan|zhenwei|jieyuan|duanbing|fenxun|guidao|luahebi|guicai|luahebi|zhenlie|wansha|" ..
		"lianpo|yicong|nosshangshi|shangshi|luaxuewei|lianying|tianyi|xianzhen|keji|huoji|xiaoji|" ..
		"xuanfeng|nosxuanfeng|jiushi|dangxian|qicai|luazaoqi|luaweimeng|" ..
		"xingshang|weiwudi_guixin|shenfen|huangen|mingshi|jianxiong|tanlan|jiang|qianxun|"..
		"tianxiang|danlao|juxiang|luaguaixiao|lualaoshi|zhichi|yicong|wusheng|wushuang|" ..
		"leiji|guhuo|nosshangshi|shangshi|zhiyu|lirang|luahailiang|buyi|lianying|tianming|jieyuan|mingshi|xiaoguo|shushen|shuiyong|" ..
		"tiandu|zhenlie|lualuji"):split("|")) do
		if str:matchOne(askill) then return askill end
	end	
end
sgs.ai_use_value.luaxuebaCard = 9
sgs.ai_use_priority.luaxuebaCard = 9.5
sgs.ai_chaofeng["wangli"] = 6
--------------词霸-------------------
--词霸：回合结束阶段，你可以选择一名其他角色并展示牌堆顶的三张牌，你获得其中的红色牌，
--并将黑色牌交给该角色，然后你对其造成X点伤害（X为黑色牌数量且最多为2）
sgs.ai_skill_invoke["luaciba"] = function(self, data)
	return #self.enemies>0
end
sgs.ai_skill_playerchosen["luaciba"] = function(self, targets)
	if #self.enemies ==0 then return nil end
	self:sort(self.enemies, "hp")
	return self.enemies[1]
end
-----------------帅气-------------------
--帅气：摸牌阶段你可以放弃摸牌，改为从1-3名角色的区域里各获得一张牌
sgs.ai_skill_use["@@luashuaiqi"] = function(self, prompt, method)	
	self:sort(self.enemies, "defense")
	local targets = {}
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhaoxingyan = self.room:findPlayerBySkillName("luaxuewei")
	local sunshangxiang = self.room:findPlayerBySkillName("xiaoji")	
	local add_player = function (player,isfriend)
		if player:isAllNude() or player:objectName()==self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.current_mode_players["rebel"] > 1 then return #targets end
		if #targets==0 then 
			table.insert(targets, player:objectName())
		elseif #targets==1 then			
			if player:objectName()~=targets[1] then 
				table.insert(targets, player:objectName()) 
			end
		elseif #targets==2 then
			if player:objectName()~=targets[1] and player:objectName()~=targets[2] then
				table.insert(targets, player:objectName()) 
			end
		end
		if isfriend and isfriend ==1 then
			self.player:setFlags("tuxi_isfriend_"..player:objectName())
		end
		return #targets
	end
	
	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount ==1 and not lord:isAllNude() then
		add_player(self.room:getLord())
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji") == 0 and jiangwei:getHandcardNum()== 1 
			and self:getEnemyNumBySeat(self.player,jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei,1) == 3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+")	end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai) == 0 ) 
			and dengai:getMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai,1) == 3 then 
		return "#luashuaiqiCard:.:->"..table.concat(targets, "+") 
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang,1) == 3 then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
		else
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhugeliang:objectName())					
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang,1) == 3 then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
				end				
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,luxun)>0 then	
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards==1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
			end
		end	
	end

	if sunshangxiang and self:isFriend(sunshangxiang) and sunshangxiang:getCards("e"):length() >0 and self:getEnemyNumBySeat(self.player,sunshangxiang)>0 then	
		if add_player(sunshangxiang,1)==3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
	end

	if zhaoxingyan and self:isFriend(zhaoxingyan) and zhaoxingyan:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,zhaoxingyan)>0 then	
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhaoxingyan:objectName())
		local cards = sgs.QList2Table(zhaoxingyan:getHandcards())
		if #cards==1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
			end
		end	
	end

	for i=1,#self.friends,1 do
		local p=self.friends[i]
		local cards = sgs.QList2Table(p:getCards("j"))
		if #cards>0 then 
			if add_player(p)==3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
		end
	end

	
	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(p)==3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if self:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|lijian", p) then
			if add_player(p)==3  then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end
		end
	end
	
	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x= p:getHandcardNum()
		local good_target=true				
		if x==1 and self:hasSkills(sgs.need_kongcheng,p) then good_target = false end
		if x>=2  and self:hasSkills("tuntian",p) then good_target = false end
		if good_target and add_player(p)==3 then return "#luashuaiqiCard:.:->"..table.concat(targets, "+") end				
	end


	if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil)) == 3 then 
		return "#luashuaiqiCard:.:->"..table.concat(targets, "+") 
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai) == 0 ) and add_player(dengai,1) == 3 then 
		return "#luashuaiqiCard:.:->"..table.concat(targets, "+") 
	end
	
	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other)>=0 and not self:hasSkills("tuntian",other) and add_player(other)==3  then
			return "#luashuaiqiCard:.:->"..table.concat(targets, "+")
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not self:hasSkills("tuntian",other) and add_player(other) == 3 and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			return "#luashuaiqiCard:.:->"..table.concat(targets, "+")
		end
	end

	return "."
end
----------------露肌-------------------
--露肌：出牌阶段，你可以展示自己的所有手牌，若你展示的手牌数不少于3，则你回复一点体力,每回合限一次
local lualuji_skill = {}
lualuji_skill.name = "lualuji"
table.insert(sgs.ai_skills, lualuji_skill)
lualuji_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isWounded() then return nil end
	if self.player:getHandcardNum()<3 then return nil end	
	if self.player:hasUsed("#lualujiCard") then return nil end
	local peach = 0	
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") then	peach =peach+1 end
	end
	if peach >= self.player:getLostHp() then return nil	end--桃的数量大于等于已损失的体力值就不发动
	if self.player:getLostHp() == 1 and self.player:getHandcardNum() >=5 then return nil end
	--只损失一点体力并且手牌数大于4时不发动。
	return sgs.Card_Parse("#lualujiCard:.:")
end
sgs.ai_skill_use_func["#lualujiCard"] = function(card, use, self)	
	use.card=card
end	
sgs.ai_use_value.lualujiCard = 8
sgs.ai_use_priority.lualujiCard = 8--这个优先级已经高于武器牌了吧
--------------善言------------
--善言：出牌阶段，你可以指定一种花色并令一名其他角色进行判定，若判定结果与你所指定的花色不相符，则你对该角色造成一点伤害，每回合限一次。
local luashanyan_skill = {}
luashanyan_skill.name = "luashanyan"
table.insert(sgs.ai_skills, luashanyan_skill)
luashanyan_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return nil end 
	if self.player:hasUsed("#luashanyanCard") then return nil end 	
	return sgs.Card_Parse("#luashanyanCard:.:")
end
sgs.ai_skill_use_func["#luashanyanCard"] = function(card, use, self)
	self:sort(self.enemies,"hp")			
	use.card=card
	target = self.enemies[1]
	if target then
		if use.to then
			use.to:append(target)
		end
	end
end	
sgs.ai_use_priority["luashanyanCard"] = 10
-------------学委----------------
--学委：每当你失去最后一张手牌时，你可以获得至多两名其他角色区域的各一张牌
sgs.ai_skill_use["@@luaxuewei"] = function(self, prompt, method)
	self:sort(self.enemies, "defense")
	local targets = {}
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhaoxingyan = self.room:findPlayerBySkillName("luaxuewei")
	local sunshangxiang = self.room:findPlayerBySkillName("xiaoji")	
	local add_player = function (player,isfriend)
		if player:isAllNude() or player:objectName()==self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.current_mode_players["rebel"] > 1 then return #targets end
		if #targets==0 then 
			table.insert(targets, player:objectName())
		elseif #targets==1 then			
			if player:objectName()~=targets[1] then 
				table.insert(targets, player:objectName()) 
			end		
		end
		if isfriend and isfriend ==1 then
			self.player:setFlags("tuxi_isfriend_"..player:objectName())
		end
		return #targets
	end
	
	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount ==1 and not lord:isAllNude() then
		add_player(self.room:getLord())
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji") == 0 and jiangwei:getHandcardNum()== 1 
			and self:getEnemyNumBySeat(self.player,jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei,1) == 2  then return "#luaxueweiCard:.:->"..table.concat(targets, "+")	end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai) == 0 ) 
			and dengai:getMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai,1) == 2 then 
		return "#luaxueweiCard:.:->"..table.concat(targets, "+") 
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang,1) == 2 then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
		else
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhugeliang:objectName())					
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang,1) == 2 then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
				end				
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,luxun)>0 then	
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards==1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==2  then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
			end
		end	
	end

	if sunshangxiang and self:isFriend(sunshangxiang) and sunshangxiang:getCards("e"):length() >0 and self:getEnemyNumBySeat(self.player,sunshangxiang)>0 then	
		if add_player(sunshangxiang,1)==2  then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
	end	

	for i=1,#self.friends,1 do
		local p=self.friends[i]
		local cards = sgs.QList2Table(p:getCards("j"))
		if #cards>0 then 
			if add_player(p)==2  then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
		end
	end

	
	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(p)==2  then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if self:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|lijian", p) then
			if add_player(p)==2  then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end
		end
	end
	
	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x= p:getHandcardNum()
		local good_target=true				
		if x==1 and self:hasSkills(sgs.need_kongcheng,p) then good_target = false end
		if x>=2  and self:hasSkills("tuntian",p) then good_target = false end
		if good_target and add_player(p)==2 then return "#luaxueweiCard:.:->"..table.concat(targets, "+") end				
	end


	if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil)) == 2 then 
		return "#luaxueweiCard:.:->"..table.concat(targets, "+") 
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai) == 0 ) and add_player(dengai,1) == 2 then 
		return "#luaxueweiCard:.:->"..table.concat(targets, "+") 
	end
	
	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other)>=0 and not self:hasSkills("tuntian",other) and add_player(other)==2  then
			return "#luaxueweiCard:.:->"..table.concat(targets, "+")
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not self:hasSkills("tuntian",other) and add_player(other) == 2 and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			return "#luaxueweiCard:.:->"..table.concat(targets, "+")
		end
	end
	for _,enemy in ipairs(self.enemies) do		
		if add_player(enemy) == 1 then return "#luaxueweiCard:.:->"..targets[1] end
	end
	return "."
end