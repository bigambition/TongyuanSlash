#include "tongyuan.h"
#include "general.h"
#include "skill.h"
#include "standard-skillcards.h"
#include "room.h"
#include "maneuvering.h"
#include "clientplayer.h"
#include "client.h"
#include "engine.h"
#include "general.h"
#include "jsonutils.h"


//----------------------建模组--------------------------------
//张作宝-同甘
TongganCard::TongganCard() {	
    will_throw = true;
    m_skillName = "tonggan";
}

bool TongganCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	if (to_select == Self||targets.length()>=2)
        return false;

	return to_select->isWounded();
}

bool TongganCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return targets.length() >0;
}

void TongganCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
    foreach(ServerPlayer *target,targets){
		RecoverStruct recover;
		recover.who = source;
		room->recover(target,recover);
	}
}

class TongganViewAsSkill: public ZeroCardViewAsSkill {
public:
    TongganViewAsSkill(): ZeroCardViewAsSkill("tonggan") {
        response_pattern = "@@tonggan";
    }

    virtual const Card *viewAs() const{
        return new TongganCard;
    }
};

class Tonggan: public TriggerSkill {
public:
    Tonggan(): TriggerSkill("tonggan") {
        events << HpRecover;
		view_as_skill = new TongganViewAsSkill;
    }

	 virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *zhangzuobao, QVariant &data) const{        
        RecoverStruct recover = data.value<RecoverStruct>();        
        bool can_invoke = false;
        QList<ServerPlayer *> other_players = room->getOtherPlayers(zhangzuobao);
        foreach (ServerPlayer *player, other_players) {
			if (player->isWounded()) {
                can_invoke = true;
                break;
            }
        }

        if (can_invoke && room->askForUseCard(zhangzuobao, "@@tonggan", "@tonggan-card")){
			room->broadcastSkillInvoke(objectName());
			room->notifySkillInvoked(zhangzuobao, objectName());
            return true; 
		}       
		return false;
    }
    
};
//张作宝-共苦
GongkuCard::GongkuCard() {	
    will_throw = true;
    m_skillName = "gongku";
}

bool GongkuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return to_select != Self && targets.length()<2;
}

bool GongkuCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return targets.length() >0;
}

void GongkuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
    foreach(ServerPlayer *target,targets){		
		room->loseHp(target);
	}
}

class GongkuViewAsSkill: public ZeroCardViewAsSkill {
public:
    GongkuViewAsSkill(): ZeroCardViewAsSkill("gongku") {
        response_pattern = "@@gongku";
    }

    virtual const Card *viewAs() const{
        return new GongkuCard;
    }
};

class Gongku: public TriggerSkill {
public:
    Gongku(): TriggerSkill("gongku") {
        events << Damaged;
		view_as_skill = new GongkuViewAsSkill;
    }

	 virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *zhangzuobao, QVariant &data) const{
        if (room->askForUseCard(zhangzuobao, "@@gongku", "@gongku-card")){
			room->broadcastSkillInvoke(objectName());
			room->notifySkillInvoked(zhangzuobao, objectName());
            return true; 
		}       
		return false;
    }
    
};

//郑敏-大腿
class Datui: public TriggerSkill {
public:
    Datui(): TriggerSkill("datui") {
        events << Dying;		
    }

	 virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *zhengmin, QVariant &data) const{
		DyingStruct dying = data.value<DyingStruct>();
        ServerPlayer *player = dying.who;
		if (player->getHp()<=0 && zhengmin->askForSkillInvoke(objectName(),data)){
			room->broadcastSkillInvoke("datui");
			JudgeStruct judge;
            judge.pattern = ".|red";
            judge.good = true;
            judge.reason = objectName();
            judge.who = zhengmin;
            room->judge(judge);
			if (judge.isGood()){
				RecoverStruct recover;
				recover.who = zhengmin;
				room->recover(player,recover);
			}
			return player->getHp()>0;
		}       
		return false;
    }
    
};

//郑敏-何必
class Hebi: public TriggerSkill {
public:
    Hebi(): TriggerSkill("hebi") {
        events << AskForRetrial;		
    }

	virtual bool triggerable(const ServerPlayer *target) const{
		if (!TriggerSkill::triggerable(target))
			return false;

		if (target->isKongcheng()) {
			bool has_red = false;
			for (int i = 0; i < 4; i++) {
				const EquipCard *equip = target->getEquip(i);
				if (equip && equip->isRed()) {
					has_red = true;
					break;
				}
			}
			return has_red;
		} else
			return true;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		JudgeStar judge = data.value<JudgeStar>();

		QStringList prompt_list;
		prompt_list << "@hebi-card" << judge->who->objectName()
			<< objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
		QString prompt = prompt_list.join(":");
		const Card *card = room->askForCard(player, ".|red", prompt, data, Card::MethodResponse, judge->who, true);

		if (card != NULL) {
			room->broadcastSkillInvoke(objectName());
			room->retrial(card, player, judge, objectName(), true);
		}
		return false;
	}
    
};

//黄磊-自残
class Zican: public TriggerSkill {
public:
	Zican(): TriggerSkill("zican") {
		events << DamageCaused;		
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *huanglei, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		ServerPlayer *victim = damage.to;
		int x = damage.damage;
		if (damage.from!=huanglei) return false;
		if (victim == huanglei) return false;
		if (victim && victim->isAlive() && huanglei->askForSkillInvoke(objectName(),data)){
			room->loseHp(huanglei,x);
			LogMessage log;
			log.type = "#zican";
			log.from = huanglei;
			log.to << victim;
			log.arg = QString::number(x);
			log.arg2 = QString::number(2*x);
			room->sendLog(log);
			damage.damage = x*2;
			data = QVariant::fromValue(damage);			
		}      
		return false;
	}

};

//陈路-奔袭
class BenxiWeapon: public TargetModSkill{
public:
	BenxiWeapon(): TargetModSkill("benxi") {		
		frequency = Compulsory;
	}

	virtual int getDistanceLimit(const Player *from, const Card *) const{
		if (from->hasSkill(objectName()) && from->getWeapon()==NULL)
			return 1000;
		else
			return 0;
	}
};

class BenxiArmor: public TriggerSkill{
public:
	BenxiArmor(): TriggerSkill("#benxi-armor") {		
		events << TargetConfirmed;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *chenlu, QVariant &data) const{
		CardUseStruct use = data.value<CardUseStruct>();
		if (chenlu && chenlu == use.from){		
			if (chenlu->getArmor()==NULL){
				foreach(ServerPlayer *p,use.to){
					if (p!=chenlu){
						p->addMark("Armor_Nullified");
					}				
				}
			}else{
				foreach(ServerPlayer *p,use.to){
					if (p->getMark("Armor_Nullified")>0){
						if(!(use.from->hasSkill("luaweimeng") && use.from->getPhase()==Player::Play)){
							p->removeMark("Armor_Nullified");
						}
					}

				}
			}
			return false;
		}
		return false;
	}
};

//陈路-扶持
FuchiCard::FuchiCard() {
	will_throw = false;
	//handling_method = Card::MethodNone;
	m_skillName = "fuchiv";
	//mute = true;
}

bool FuchiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select->hasLordSkill("fuchi")
		&& to_select != Self && !to_select->hasFlag("FuchiInvoked");
}

void FuchiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	ServerPlayer *chenlu = targets.first();
	if (chenlu->hasLordSkill("fuchi")) {
		room->setPlayerFlag(chenlu, "FuchiInvoked");

		if (!chenlu->isLord() && chenlu->hasSkill("Laoban"))
			room->broadcastSkillInvoke("Laoban");
		else
			room->broadcastSkillInvoke("fuchi");

		room->notifySkillInvoked(chenlu, "fuchi");
		chenlu->obtainCard(this,false);
		QList<int> subcards = this->getSubcards();
		if(subcards.length()>2){
			QStringList prompt_list;
			prompt_list << "@fuchiv-card" << QString::number(subcards.length()-2);
			QString prompt = prompt_list.join(":");
			const Card *cards = room->askForExchange(chenlu,objectName(),subcards.length()-2,true,prompt);
			source->obtainCard(cards,false);
		}		
		QList<ServerPlayer *> chenlus;
		QList<ServerPlayer *> players = room->getOtherPlayers(source);
		foreach (ServerPlayer *p, players) {
			if (p->hasLordSkill("fuchi") && !p->hasFlag("FuchiInvoked"))
				chenlus << p;
		}
		if (chenlus.empty())
			room->setPlayerFlag(source, "ForbidFuchi");
	}
}

class FuchiViewAsSkill: public ViewAsSkill {
public:
	FuchiViewAsSkill(): ViewAsSkill("fuchiv") {
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		return true;
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.isEmpty())
			return NULL;

		FuchiCard *card = new FuchiCard;
		card->addSubcards(cards);
		//card->setSkillName(objectName());
		return card;
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->getKingdom() == "mo" && !player->hasFlag("ForbidFuchi");
	}
	
};

class Fuchi: public TriggerSkill {
public:
	Fuchi(): TriggerSkill("fuchi$") {
		events << GameStart << EventAcquireSkill << EventLoseSkill << EventPhaseChanging;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if ((triggerEvent == GameStart && player->isLord())
			|| (triggerEvent == EventAcquireSkill && data.toString() == "fuchi")) {
				QList<ServerPlayer *> lords;
				foreach (ServerPlayer *p, room->getAlivePlayers()) {
					if (p->hasLordSkill(objectName()))
						lords << p;
				}
				if (lords.isEmpty()) return false;

				QList<ServerPlayer *> players;
				if (lords.length() > 1)
					players = room->getAlivePlayers();
				else
					players = room->getOtherPlayers(lords.first());
				foreach (ServerPlayer *p, players) {
					if (!p->hasSkill("fuchiv"))
						room->attachSkillToPlayer(p, "fuchiv");
				}
		} else if (triggerEvent == EventLoseSkill && data.toString() == "fuchi") {
			QList<ServerPlayer *> lords;
			foreach (ServerPlayer *p, room->getAlivePlayers()) {
				if (p->hasLordSkill(objectName()))
					lords << p;
			}
			if (lords.length() > 2) return false;

			QList<ServerPlayer *> players;
			if (lords.isEmpty())
				players = room->getAlivePlayers();
			else
				players << lords.first();
			foreach (ServerPlayer *p, players) {
				if (p->hasSkill("fuchiv"))
					room->detachSkillFromPlayer(p, "fuchiv", true);
			}
		} else if (triggerEvent == EventPhaseChanging) {
			PhaseChangeStruct phase_change = data.value<PhaseChangeStruct>();
			if (phase_change.from != Player::Play)
				return false;
			if (player->hasFlag("ForbidFuchi"))
				room->setPlayerFlag(player, "-ForbidFuchi");
			QList<ServerPlayer *> players = room->getOtherPlayers(player);
			foreach (ServerPlayer *p, players) {
				if (p->hasFlag("FuchiInvoked"))
					room->setPlayerFlag(p, "-FuchiInvoked");
			}
		}
		return false;
	}
};

//张凡-女汉
class Nvhan: public TriggerSkill {
public:
	Nvhan(): TriggerSkill("nvhan") {
		events <<GameStart<< EventPhaseStart<< EventPhaseChanging;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room *room, ServerPlayer *zhangfan, QVariant &data) const{
		if (triggerEvent == GameStart)
			zhangfan->gainMark("@female");
		else if(triggerEvent == EventPhaseStart){
			if (zhangfan->getPhase()==Player::Start){				
				if(zhangfan->getMark("@female")>0 && zhangfan->askForSkillInvoke(objectName(),data)){
					zhangfan->loseMark("@female");
					zhangfan->setGender(General::Male);
					zhangfan->gainMark("@male");
					room->handleAcquireDetachSkills(zhangfan, "wushuang|paoxiao|wusheng");
					//room->broadcastSkillInvoke("nvhan");
					room->notifySkillInvoked(zhangfan, "nvhan");
				}
			}			
		}else if (triggerEvent == EventPhaseChanging){
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if (change.to == Player::NotActive){
				room->handleAcquireDetachSkills(zhangfan, "-wushuang|-paoxiao|-wusheng",true);				
			}
		}
		return false;
	}
};

//张凡-萌妹
class Mengmei: public TriggerSkill {
public:
	Mengmei(): TriggerSkill("mengmei") {
		events << EventPhaseStart;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room *room, ServerPlayer *zhangfan, QVariant &data) const{
		if(zhangfan->getPhase()==Player::Finish){
			LogMessage log;
			log.type = "#mengmei";
			log.from = zhangfan;			
			log.arg = objectName();			
			room->sendLog(log);
			//room->broadcastSkillInvoke("mengmei");
			room->notifySkillInvoked(zhangfan, "mengmei");
			if (zhangfan->getMark("@male")>0 ){
				zhangfan->loseMark("@male");
				zhangfan->setGender(General::Female);
				zhangfan->gainMark("@female");
				room->loseHp(zhangfan);				
			}else if(zhangfan->getMark("@female")>0){
				zhangfan->drawCards(2);
			}
		}
		return false;
	}
};

//屈严-圈圈
QuanquanCard::QuanquanCard() {	
	will_throw = false;
	target_fixed = true;
	m_skillName = "quanquan";
}

void QuanquanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	source->addToPile("QQ", this);
}

class QuanquanViewAsSkill: public ViewAsSkill {
public:
	QuanquanViewAsSkill(): ViewAsSkill("quanquan") {
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		return selected.length()<3 && to_select->getTypeId() == Card::TypeBasic;
	}

	virtual bool isEnabledAtPlay(const Player *) const{
		return false;
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		return pattern=="@@quanquan";
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.isEmpty())
			return NULL;

		QuanquanCard *card = new QuanquanCard;
		card->addSubcards(cards);
		//card->setSkillName(objectName());
		return card;
	}
};

class Quanquan: public TriggerSkill {
public:
	Quanquan(): TriggerSkill("quanquan") {
		events << EventPhaseStart;
		view_as_skill = new QuanquanViewAsSkill;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *quyan, QVariant &data) const{ 
		if(triggerEvent == EventPhaseStart){			
			bool can_invoke = false;
			foreach(const Card *card,quyan->getHandcards()){
				if(card->getTypeId() == Card::TypeBasic && quyan->getPile("QQ").isEmpty()){
					can_invoke = true;
					break;
				}
			}
			if (can_invoke && quyan->getPhase() == Player::Discard &&room->askForUseCard(quyan, "@@quanquan", "@quanquan-card")){
				room->broadcastSkillInvoke(objectName());
				room->notifySkillInvoked(quyan, objectName());				
			}       
		}
		return false;
	}
};
//屈严-圈圈攻击范围
class QuanquanTargetMod: public TargetModSkill {
public:
	QuanquanTargetMod(): TargetModSkill("#quanquan-target") {
		frequency = NotFrequent;
	}
	

	virtual int getDistanceLimit(const Player *from, const Card *) const{
		if (from->getPile("QQ").length()>0)
			return from->getPile("QQ").length();
		else
			return 0;
	}
};
//圈圈-去除牌堆
class QuanquanClear: public TriggerSkill{
public:
	QuanquanClear(): TriggerSkill("#quanquan-clear"){
		events<<EventLoseSkill<<Death;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *quyan, QVariant &data) const{
		if(triggerEvent == EventLoseSkill){
			if(data.toString() == "quanquan" && !quyan->getPile("QQ").isEmpty())
				quyan->removePileByName("QQ");
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == quyan && !quyan->getPile("QQ").isEmpty())
				quyan->removePileByName("QQ");
		}
		return false;
	}
};

//屈严-小胖
XiaopangCard::XiaopangCard() {
	m_skillName = "xiaopang";
}

bool XiaopangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	QString name;
	const Card *card = NULL;
	if (!user_string.isEmpty()) {
		name = user_string.split("+").first();
		card = Sanguosha->cloneCard(name);
	}
	return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool XiaopangCard::targetFixed() const{
	if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
		return true;

	const Card *card = NULL;
	if (!user_string.isEmpty())
		card = Sanguosha->cloneCard(user_string.split("+").first());
	return card && card->targetFixed();
}

bool XiaopangCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
	QString name;
	const Card *card = NULL;
	if (!user_string.isEmpty()) {
		name = user_string.split("+").first();
		card = Sanguosha->cloneCard(name);
	}
	return card && card->targetsFeasible(targets, Self);
}

void XiaopangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	QList<int> cards = source->getPile("QQ");
	room->fillAG(cards, source);
	int card_id = room->askForAG(source, cards, false, "quanquan");
	room->clearAG();
	if (card_id != -1) {
		CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "quanquan", QString());
		room->throwCard(Sanguosha->getCard(card_id), reason, NULL);
		QString name = user_string.split("+").first();	
		const Card *card = Sanguosha->cloneCard(name);
		if(Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE){
			room->useCard(CardUseStruct(card, source, targets));
			/*LogMessage log;
			log.type = "#xiaopang1";
			log.from = source;
			log.to = targets;
			log.arg = card->objectName();	
			room->sendLog(log);*/
		}
	}
}

class XiaopangViewAsSkill: public ZeroCardViewAsSkill {
public:
	XiaopangViewAsSkill(): ZeroCardViewAsSkill("xiaopang") {
	}

	virtual bool isEnabledAtPlay(const Player *) const{
		return false;
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		if (player->getPhase() != Player::NotActive || player->getPile("QQ").isEmpty()) return false;
		if (pattern == "slash")
			return Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE;
		else if (pattern == "peach")
			return !player->hasFlag("Global_PreventPeach");
		else if (pattern.contains("analeptic"))
			return true;
		return false;		
	}

	virtual const Card *viewAs() const{
		XiaopangCard *Xiaopang_card = new XiaopangCard;
		QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
		if (pattern == "peach+analeptic" && Self->hasFlag("Global_PreventPeach"))
			pattern = "analeptic";
		Xiaopang_card->setUserString(pattern);
		return Xiaopang_card;
	}
};

class Xiaopang: public TriggerSkill {
public:
	Xiaopang(): TriggerSkill("xiaopang") {
		events << CardAsked;
		view_as_skill = new XiaopangViewAsSkill;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *quyan, QVariant &data) const{
		if(quyan->getPile("QQ").isEmpty()) return false;		
		QString pattern = data.toStringList().first();		
			if (quyan->getPhase() == Player::NotActive 
				&& (pattern.contains("slash") || pattern.contains("jink"))
				&& room->askForSkillInvoke(quyan, objectName(), data)) {
				QList<int> cards = quyan->getPile("QQ");
				room->fillAG(cards, quyan);
				int card_id = room->askForAG(quyan, cards, false, "xiaopang");
				room->clearAG();
				if (card_id != -1) {
					CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "xiaopang", QString());
					room->throwCard(Sanguosha->getCard(card_id), reason, NULL);
					if(pattern.contains("slash")){
						Slash *slash = new Slash(Card::NoSuit, 0);
						slash->setSkillName(objectName());
						room->provide(slash);						
						//return true;
					}else if(pattern.contains("jink")){
						Jink *jink = new Jink(Card::NoSuit, 0);
						jink->setSkillName(objectName());
						room->provide(jink);						
						//return true;
					}					
					/*return false;*/
				}
				/*return false;*/
			}
			return false;			
	}
};

//上官端森-厚积
class Houji: public TriggerSkill{
public:
	Houji(): TriggerSkill("houji"){
		events<<EventPhaseStart;
		frequency = Frequent;
	}
	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *shangguanduansen, QVariant &data) const{
		if(shangguanduansen->getPhase()!=Player::Start) return false;
		bool can_invoke = false;
		foreach(ServerPlayer *p,room->getAlivePlayers()){
			if(shangguanduansen->getHp()<p->getHp()){
				can_invoke = true;
				break;
			}
		}
		if(can_invoke == false) return false;
		if(!shangguanduansen->askForSkillInvoke(objectName(),data)) return false;
		if(!shangguanduansen->isWounded()) 
			shangguanduansen->drawCards(2);
		else{
			QString choice = room->askForChoice(shangguanduansen,objectName(),"recover+draw",data);
			if(choice == "draw") 
				shangguanduansen->drawCards(2);
			else{
				RecoverStruct recover;
				recover.who = shangguanduansen;
				room->recover(shangguanduansen,recover);
			}
		}		
		return false;
	}
};

//上官端森-薄发
class Bofa: public TriggerSkill{
public:
	Bofa(): TriggerSkill("bofa"){
		events<<DamageCaused;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room *room,ServerPlayer *shangguanduansen,QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		int x = damage.damage;
		if(!(damage.to && damage.to->isAlive() && damage.to !=shangguanduansen && 
			shangguanduansen->isWounded() && damage.from==shangguanduansen)) return false;
		LogMessage log;
		log.type = "#bofa";
		log.from = shangguanduansen;
		log.to << damage.to;
		log.arg = QString::number(x);
		log.arg2 = QString::number(x+shangguanduansen->getLostHp());
		room->sendLog(log);
		damage.damage = damage.damage + shangguanduansen->getLostHp();
		data = QVariant::fromValue(damage);	
		room->notifySkillInvoked(shangguanduansen, objectName());
		return false;
	}
};

//陆瑞琨-口味
class Kouwei: public TriggerSkill {
public:
	Kouwei(): TriggerSkill("kouwei") {
		events << DamageCaused << DamageInflicted;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *luruikun, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if (triggerEvent == DamageCaused) {
			if (damage.to && damage.to->isAlive() && damage.to != luruikun && luruikun->canDiscard(luruikun, "he")
				&& room->askForCard(luruikun, ".|black", "@kouwei-increase:" + damage.to->objectName(), data, objectName())) {
					room->broadcastSkillInvoke(objectName(), 1);
					LogMessage log;
					log.type = "#kouweiIncrease";
					log.from = luruikun;
					log.arg = QString::number(damage.damage);
					log.arg2 = QString::number(++damage.damage);
					room->sendLog(log);
					data = QVariant::fromValue(damage);
			}
		} else if (triggerEvent == DamageInflicted) {
			if (damage.from && damage.from->isAlive() && damage.from != luruikun && luruikun->canDiscard(luruikun, "he")
				&& room->askForCard(luruikun, ".|red", "@kouwei-decrease:" + damage.from->objectName(), data, objectName())) {
					room->broadcastSkillInvoke(objectName(), 2);
					LogMessage log;
					log.type = "#kouweiDecrease";
					log.from = luruikun;
					log.arg = QString::number(damage.damage);
					log.arg2 = QString::number(--damage.damage);
					room->sendLog(log);
					data = QVariant::fromValue(damage);
					if (damage.damage < 1)
						return true;
			}
		}
		return false;
	}
};

//鲍丙瑞-大头
class Datou: public TriggerSkill{
public:
	Datou(): TriggerSkill("datou"){
		events << TargetConfirmed;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		CardUseStruct use = data.value<CardUseStruct>();
		if (use.card == NULL || !use.card->isKindOf("Slash"))
			return false;
		foreach(ServerPlayer *p, use.to){
			if ((player->distanceTo(p) <= 1 || player == p) && player->askForSkillInvoke(objectName(), QVariant::fromValue(p))){
				player->drawCards(1);
				if (player != p){
					const Card *c = room->askForExchange(player, objectName(), 1);
					const Card *realcard = Sanguosha->getCard(c->getEffectiveId());

					p->obtainCard(realcard, true);
					if (realcard->isKindOf("EquipCard") && p->isAlive() && !p->isCardLimited(realcard, Card::MethodUse)){
						room->useCard(CardUseStruct(realcard, p, p));
					}
				}
			}
		}
		return false;
	}
};

//张海明-飞羽
class Feiyu: public DrawCardsSkill {
public:
	Feiyu(): DrawCardsSkill("feiyu") {
		frequency = Frequent;
	}

	virtual int getDrawNum(ServerPlayer *zhanghaiming, int n) const{
		Room *room = zhanghaiming->getRoom();
		if (room->askForSkillInvoke(zhanghaiming, objectName()))			
			return n + zhanghaiming->getEquips().length()/2+1;
		else
			return n;
	}
};

//赵岩-回家
class Huijia: public TriggerSkill{
public:
	Huijia(): TriggerSkill("huijia"){
		events<<EventPhaseStart;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer *zhaoyan,QVariant &data) const{
		if(zhaoyan->getPhase()== Player::Finish && zhaoyan->askForSkillInvoke(objectName(),data))
			zhaoyan->drawCards(1);
		return false;
	}
};

//赵岩-毕业
class Biye: public TriggerSkill{
public:
	Biye(): TriggerSkill("biye"){
		events<<DamageInflicted;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* zhaoyan,QVariant& data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if(!damage.from || damage.from == zhaoyan ||damage.to != zhaoyan) return false;
		LogMessage log;
		log.type = "#biye";
		log.from = zhaoyan;		
		room->sendLog(log);
		room->notifySkillInvoked(zhaoyan, objectName());
		JudgeStruct judge;
		judge.pattern = ".|.|1,3,5,6,9,10,12,13|.";
		judge.reason = objectName();
		judge.who = zhaoyan;
		judge.good = true;
		room->judge(judge);
		if(judge.isGood()){
			if(judge.card->getNumber() == 1||judge.card->getNumber() == 5 
				|| judge.card->getNumber() == 10||judge.card->getNumber() == 13){
					DamageStruct da;
					da.from = zhaoyan;
					da.to = damage.from;
					room->damage(da);
					if(!zhaoyan->isAlive())
						return true;
			}else if(judge.card->getNumber() == 3 || judge.card->getNumber() == 6
				||judge.card->getNumber() == 9||judge.card->getNumber() == 12){
					LogMessage log1;
					log1.type = "#biye1";
					log1.from = zhaoyan;
					log1.to<< damage.from;
					room->sendLog(log1);
					return true;
			}
							
		}
		return false;
	}
};

//谢刚-建模
class Jianmo: public TriggerSkill {
public:
	Jianmo(): TriggerSkill("jianmo") {
		events << Damaged << CardsMoveOneTime<<EventLoseSkill<<Death;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if (triggerEvent == CardsMoveOneTime) {
			if (player->getPhase() == Player::Discard) {
				CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
				if (move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
					int n = move.card_ids.length();
					if (n > 0) {
						room->broadcastSkillInvoke(objectName());
						room->notifySkillInvoked(player, objectName());
						player->gainMark("@mo", n);
					}
				}
			}
		} else if (triggerEvent == Damaged) {
			room->broadcastSkillInvoke(objectName());
			room->notifySkillInvoked(player, objectName());
			DamageStruct damage = data.value<DamageStruct>();
			player->gainMark("@mo", damage.damage);
		}else if(triggerEvent == EventLoseSkill && data.toString() == "jianmo"){
			if(player->getMark("@mo")>0)
				player->loseAllMarks("@mo");
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == player && player->getMark("@mo")>0)
				player->loseAllMarks("@mo");
		}
		return false;
	}
};

//谢刚-建模加手牌上限
class JianmoMaxCard: public MaxCardsSkill{
public:
	JianmoMaxCard(): MaxCardsSkill("#jianmo-card"){
	}

	virtual int getExtra(const Player *target) const{
		if (target->hasSkill(objectName())) {			
			return target->getMark("@mo");
		} else
			return 0;
	}
};

//谢刚-优化 
class Youhua: public PhaseChangeSkill {
public:
	Youhua(): PhaseChangeSkill("youhua") {
		frequency = Wake;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL && PhaseChangeSkill::triggerable(target)
			&& target->getPhase() == Player::Start
			&& target->getMark("youhua") == 0
			&& target->getMark("@mo") >= 3;
	}

	virtual bool onPhaseChange(ServerPlayer *zhaoyan) const{
		Room *room = zhaoyan->getRoom();
		room->broadcastSkillInvoke(objectName());
		room->notifySkillInvoked(zhaoyan, objectName());
		//room->doLightbox("$YouhuaAnimate");

		LogMessage log;
		log.type = "#YouhuaWake";
		log.from = zhaoyan;
		log.arg = QString::number(zhaoyan->getMark("@mo"));
		room->sendLog(log);

		room->setPlayerMark(zhaoyan, "youhua", 1);
		if (room->changeMaxHpForAwakenSkill(zhaoyan))
			room->acquireSkill(zhaoyan, "fangzhen");

		return false;
	}
};

//谢刚-仿真:一名其他角色的回合开始时，你可以弃置一个“模”标记，然后获得该角色的一项武将技能直到你的回合结束 
class Fangzhen: public TriggerSkill{
public:
	Fangzhen(): TriggerSkill("fangzhen"){
		events<<EventPhaseStart<<EventPhaseChanging<<EventLoseSkill<<Death;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room* room,ServerPlayer* player,QVariant& data) const{
		if(triggerEvent == EventPhaseStart){
			ServerPlayer *zhaoyan = room->findPlayerBySkillName(objectName());
			if(!zhaoyan || player == zhaoyan) return false;
			if(player->getPhase() != Player::RoundStart) return false;
			QStringList skill_names;			
			QString skill_name;
			foreach (const Skill *skill, player->getVisibleSkillList(false)) {
				if (/*skill->isLordSkill()
					|| skill->getFrequency() == Skill::Limited
					|| skill->getFrequency() == Skill::Wake ||*/
					(skill->objectName()=="laobao" || skill->objectName() == "weidi") && zhaoyan->getRole() == "lord")
					continue;
				if (!skill_names.contains(skill->objectName())) {				
					skill_names << skill->objectName();
				}
			}	
			if (skill_names.isEmpty()) return false;			
			if(zhaoyan->getMark("@mo")==0 || !zhaoyan->askForSkillInvoke(objectName(),data)) return false;
			zhaoyan->loseMark("@mo");		
			skill_name = room->askForChoice(zhaoyan,objectName(), skill_names.join("+"),data);
			QStringList new_skills = room->getTag("new_skill").toString().split("+");
			new_skills<<skill_name;
			room->acquireSkill(zhaoyan,skill_name,true);
			LogMessage log;
			log.type = "#fangzhen";
			log.from = zhaoyan;
			log.to<<player;
			log.arg = skill_name;
			room->sendLog(log);
			room->setTag("new_skill",QVariant::fromValue(new_skills.join("+")));
		}else if(triggerEvent == EventPhaseChanging){
			ServerPlayer *zhaoyan = room->findPlayerBySkillName(objectName());
			if(!zhaoyan || zhaoyan->getPhase() == Player::NotActive) return false;
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();			
			if(change.to != Player::NotActive) return false;			
			QStringList new_skills = room->getTag("new_skill").toString().split("+");
			room->removeTag("new_skill");
			foreach(QString skill,new_skills){
				if(zhaoyan->hasSkill(skill))
					room->detachSkillFromPlayer(zhaoyan,skill);
			}						
		}else if(triggerEvent == EventLoseSkill){
			if(data.toString()!=objectName()) return false;
			ServerPlayer* zhaoyan = room->findPlayerBySkillName(objectName());
			if(!zhaoyan) return false;
			QStringList new_skills = room->getTag("new_skill").toString().split("+");
			room->removeTag("new_skill");
			foreach(QString skill,new_skills){
				if(zhaoyan->hasSkill(skill))
					room->detachSkillFromPlayer(zhaoyan,skill);
			}
		}else if(triggerEvent == Death){
			ServerPlayer *zhaoyan = room->findPlayerBySkillName(objectName());
			DeathStruct death = data.value<DeathStruct>();
			if(!zhaoyan || death.who != zhaoyan) return false;
			QStringList new_skills = room->getTag("new_skill").toString().split("+");
			room->removeTag("new_skill");
			foreach(QString skill,new_skills){
				if(zhaoyan->hasSkill(skill))
					room->detachSkillFromPlayer(zhaoyan,skill);
			}
		}
		return false;
	}
};

//谢刚-拥护 
class Yonghu: public TriggerSkill {
public:
	Yonghu(): TriggerSkill("yonghu$") {
		events << FinishJudge;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL && target->getKingdom() == "mo";
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		JudgeStar judge = data.value<JudgeStar>();
		CardStar card = judge->card;

		if (card->isRed()) {
			QList<ServerPlayer *> caopis;
			foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
				if (p->hasLordSkill(objectName()))
					caopis << p;
			}

			while (!caopis.isEmpty()) {
				ServerPlayer *caopi = room->askForPlayerChosen(player, caopis, objectName(), "@yonghu-to", true);
				if (caopi) {
					if (!caopi->isLord() && caopi->hasSkill("weidi"))
						room->broadcastSkillInvoke("weidi");
					else
						room->broadcastSkillInvoke(objectName());

					room->notifySkillInvoked(caopi, objectName());
					LogMessage log;
					log.type = "#InvokeOthersSkill";
					log.from = player;
					log.to << caopi;
					log.arg = objectName();
					room->sendLog(log);

					caopi->drawCards(1);
					caopis.removeOne(caopi);
				} else
					break;
			}
		}

		return false;
	}
};

//徐学海-弃博
QiboCard::QiboCard() {
	target_fixed = true;
}

void QiboCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
	room->loseHp(source);
	if (source->isAlive())
		room->drawCards(source, 2);
}

class Qibo: public ZeroCardViewAsSkill {
public:
	Qibo(): ZeroCardViewAsSkill("qibo") {
	}

	virtual const Card *viewAs() const{
		return new QiboCard;
	}
};

//丁吉-液压
class Yeya: public OneCardViewAsSkill {
public:
	Yeya(): OneCardViewAsSkill("yeya") {
	}

	virtual bool viewFilter(const Card *to_select) const{
		const Card *card = to_select;

		switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
		case CardUseStruct::CARD_USE_REASON_PLAY: {
			if(!Analeptic::IsAvailable(Self))
				return card->isKindOf("Analeptic");
			else
				return card->isKindOf("Slash") || card->isKindOf("Analeptic");
			 }
		case CardUseStruct::CARD_USE_REASON_RESPONSE:
		case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
			QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
			if (pattern == "slash")
				return card->isKindOf("Analeptic");
			else if (pattern.contains("analeptic"))
				return card->isKindOf("Slash");
			 }
		default:
			return false;
		}
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return Slash::IsAvailable(player) || Analeptic::IsAvailable(player);
		
	}

	virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
		return pattern.contains("analeptic") || pattern == "slash";
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		if (originalCard->isKindOf("Slash")) {
			Analeptic *analeptic = new Analeptic(originalCard->getSuit(), originalCard->getNumber());
			analeptic->addSubcard(originalCard);
			analeptic->setSkillName(objectName());
			return analeptic;
		} else if (originalCard->isKindOf("Analeptic")) {
			Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
			slash->addSubcard(originalCard);
			slash->setSkillName(objectName());
			return slash;
		} else
			return NULL;
	}
};

//丁吉-前进 
class Qianjin: public DistanceSkill {
public:
	Qianjin(): DistanceSkill("qianjin") {
	}

	virtual int getCorrect(const Player *from, const Player *) const{
		if (from->hasSkill(objectName()))
			return -1;
		else
			return 0;
	}
};

//朱锋-培训
class Peixun: public TriggerSkill{
public:
	Peixun(): TriggerSkill("peixun"){
		events<<EventPhaseStart;
	}
	
	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && !target->hasSkill(objectName());
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* player,QVariant& data) const{
		if(player->getPhase() != Player::Finish) return false;
		ServerPlayer *zhufeng = room->findPlayerBySkillName(objectName());
		if(!zhufeng || zhufeng->isKongcheng() || !zhufeng->canDiscard(zhufeng,"h")||!zhufeng->askForSkillInvoke(objectName(),data)) return false;
		if(!room->askForDiscard(zhufeng,objectName(),1,1,false,false,"#peixun")) return false;
		QString choice;
		if(player->getCardCount(true) <2 || !player->canDiscard(player,"he"))
			choice = "damage";
		else
			choice = room->askForChoice(player,objectName(),"discard1+damage",data);
		if(choice == "damage"){
			DamageStruct damage;
			damage.from = zhufeng;
			damage.to = player;
			room->damage(damage);
		}else{
			room->askForDiscard(player,objectName(),2,2,false,true,"#peixun_discard");
			RecoverStruct recover;
			recover.who = zhufeng;
			room->recover(player,recover);
		}
		return false;
	}
};

//陈昌-援助 
YuanzhuCard::YuanzhuCard() {
	mute = true;
	will_throw = false;
	handling_method = Card::MethodNone;
}

bool YuanzhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	if (!targets.isEmpty())
		return false;

	const Card *card = Sanguosha->getCard(subcards.first());
	const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
	int equip_index = static_cast<int>(equip->location());
	return to_select->getEquip(equip_index) == NULL;
}

void YuanzhuCard::onEffect(const CardEffectStruct &effect) const{
	ServerPlayer *caohong = effect.from;
	Room *room = caohong->getRoom();
	room->moveCardTo(this, caohong, effect.to, Player::PlaceEquip,
		CardMoveReason(CardMoveReason::S_REASON_PUT, caohong->objectName(), "yuanzhu", QString()));

	const Card *card = Sanguosha->getCard(subcards.first());

	LogMessage log;
	log.type = "$NvzongEquip";
	log.from = effect.to;
	log.card_str = QString::number(card->getEffectiveId());
	room->sendLog(log);

	if (card->isKindOf("Weapon")) {
		QList<ServerPlayer *> targets;
		foreach (ServerPlayer *p, room->getAllPlayers()) {
			if (effect.to->distanceTo(p) == 1 && caohong->canDiscard(p, "hej"))
				targets << p;
		}
		if (!targets.isEmpty()) {
			ServerPlayer *to_dismantle = room->askForPlayerChosen(caohong, targets, "yuanzhu", "@yuanzhu-discard:" + effect.to->objectName());
			int card_id = room->askForCardChosen(caohong, to_dismantle, "hej", "yuanzhu", false, Card::MethodDiscard);
			room->throwCard(Sanguosha->getCard(card_id), to_dismantle, caohong);
		}
	} else if (card->isKindOf("Armor")) {
		effect.to->drawCards(1);
	} else if (card->isKindOf("Horse")) {
		RecoverStruct recover;
		recover.who = effect.from;
		room->recover(effect.to, recover);
	}
}

class YuanzhuViewAsSkill: public OneCardViewAsSkill {
public:
	YuanzhuViewAsSkill(): OneCardViewAsSkill("yuanzhu") {
		filter_pattern = "EquipCard";
		response_pattern = "@@yuanzhu";
	}	

	virtual const Card *viewAs(const Card *originalcard) const{
		YuanzhuCard *first = new YuanzhuCard;
		first->addSubcard(originalcard->getId());
		first->setSkillName(objectName());
		return first;
	}
};

class Yuanzhu: public PhaseChangeSkill {
public:
	Yuanzhu(): PhaseChangeSkill("yuanzhu") {
		view_as_skill = new YuanzhuViewAsSkill;
	}

	virtual bool onPhaseChange(ServerPlayer *target) const{
		Room *room = target->getRoom();
		if (target->getPhase() == Player::Finish && !target->isNude())
			room->askForUseCard(target, "@@yuanzhu", "@yuanzhu-equip", -1, Card::MethodNone);
		return false;
	}
};

//何姗-撤离
class Cheli: public TriggerSkill {
public:
	Cheli(): TriggerSkill("cheli") {
		events << EventPhaseStart;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const{
		if (player->getPhase() != Player::Finish)
			return false;
		ServerPlayer *yuejin = room->findPlayerBySkillName(objectName());
		if (!yuejin || yuejin == player)
			return false;
		if (yuejin->canDiscard(yuejin, "h") && room->askForCard(yuejin, ".Basic", "@cheli", QVariant(), objectName())) {
			room->broadcastSkillInvoke(objectName(), 1);
			if (!room->askForCard(player, ".Equip", "@cheli-discard", QVariant())) {
				room->broadcastSkillInvoke(objectName(), 2);
				room->damage(DamageStruct("cheli", yuejin, player));
			} else {
				room->broadcastSkillInvoke(objectName(), 3);
				if (yuejin->isAlive())
					yuejin->drawCards(1);
			}
		}
		return false;
	}
};

//马中帆-卧槽
class Wocao: public TriggerSkill{
public:
	Wocao(): TriggerSkill("wocao"){
		events<<TargetConfirming;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer *mazhongfan,QVariant& data) const{
		CardUseStruct usestruct = data.value<CardUseStruct>();
		if(!usestruct.card||!usestruct.from || usestruct.from == mazhongfan || !usestruct.to.contains(mazhongfan)|| 
			!usestruct.card->isKindOf("Slash") ||!mazhongfan->canDiscard(mazhongfan,"h")) return false;
		if(mazhongfan->askForSkillInvoke(objectName(),data)){
			if(room->askForDiscard(mazhongfan,objectName(),1,1,false,false,"#wocao")){
				Slash *slash = new Slash(Card::NoSuit,0);
				slash->setSkillName(objectName());
				room->useCard(CardUseStruct::CardUseStruct(slash,mazhongfan,usestruct.from));
			}			
		}
		return false;
	}
};

//马中帆-泥马
class Nima: public TriggerSkill{
public:
	Nima(): TriggerSkill("nima"){
		events<<SlashMissed;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer *mazhongfan,QVariant& data) const{
		SlashEffectStruct effect = data.value<SlashEffectStruct>();
		if(!effect.to || effect.to == mazhongfan || effect.from != mazhongfan || !mazhongfan->canDiscard(mazhongfan,"h")
			|| !mazhongfan->askForSkillInvoke(objectName(),data)) return false;
		if(room->askForDiscard(mazhongfan,objectName(),1,1,false,false,"#nima")){
			Slash *slash = new Slash(Card::NoSuit,0);
			slash->setSkillName(objectName());
			room->useCard(CardUseStruct::CardUseStruct(slash,mazhongfan,effect.to));
		}
		return false;
	}
};


//-------------------武汉研发部、嵌入式组----------------------
//刘奇-算法
class Suanfa: public TriggerSkill{
public:
	Suanfa(): TriggerSkill("suanfa"){
		events<<EventPhaseChanging<<Damaged;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room* room,ServerPlayer* liuqi,QVariant &data) const{
		if(triggerEvent == EventPhaseChanging){
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if(change.to != Player::Draw) return false;
			if(liuqi->isSkipped(Player::Draw)) return false;
			if(liuqi->askForSkillInvoke(objectName(),data)){
				liuqi->skip(Player::Draw);
				QList<int> card_ids = room->getNCards(4);
				room->fillAG(card_ids);
				QList<int> to_get, to_throw;
				while (true) {
					int sum = 0;
					foreach (int id, to_get)
						sum += Sanguosha->getCard(id)->getNumber();
					foreach (int id, card_ids) {
						if (sum + Sanguosha->getCard(id)->getNumber() > 13) {
							room->takeAG(NULL, id, false);
							card_ids.removeOne(id);
							to_throw << id;
						}
					}
					if (card_ids.isEmpty()) break;
					int card_id = room->askForAG(liuqi, card_ids, card_ids.length() < 4, objectName());
					if (card_id == -1) break;
					card_ids.removeOne(card_id);
					to_get << card_id;
					room->takeAG(liuqi, card_id, false);
					if (card_ids.isEmpty()) break;
				}
				DummyCard *dummy = new DummyCard;
				if (!to_get.isEmpty()) {
					dummy->addSubcards(to_get);
					liuqi->obtainCard(dummy);
				}
				dummy->clearSubcards();
				if (!to_throw.isEmpty() || !card_ids.isEmpty()) {
					dummy->addSubcards(to_throw + card_ids);
					CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, liuqi->objectName(), objectName(), QString());
					room->throwCard(dummy, reason, NULL);
				}
				delete dummy;
				room->clearAG();	
				return true;
			}		
		}else if(triggerEvent == Damaged){
			DamageStruct damage = data.value<DamageStruct>();
			if(damage.to != liuqi) return false;
			if(liuqi->askForSkillInvoke(objectName(),data)){				
				QList<int> card_ids = room->getNCards(4);
				room->fillAG(card_ids);
				QList<int> to_get, to_throw;
				while (true) {
					int sum = 0;
					foreach (int id, to_get)
						sum += Sanguosha->getCard(id)->getNumber();
					foreach (int id, card_ids) {
						if (sum + Sanguosha->getCard(id)->getNumber() > 13) {
							room->takeAG(NULL, id, false);
							card_ids.removeOne(id);
							to_throw << id;
						}
					}
					if (card_ids.isEmpty()) break;
					int card_id = room->askForAG(liuqi, card_ids, card_ids.length() < 4, objectName());
					if (card_id == -1) break;
					card_ids.removeOne(card_id);
					to_get << card_id;
					room->takeAG(liuqi, card_id, false);
					if (card_ids.isEmpty()) break;
				}
				DummyCard *dummy = new DummyCard;
				if (!to_get.isEmpty()) {
					dummy->addSubcards(to_get);
					liuqi->obtainCard(dummy);
				}
				dummy->clearSubcards();
				if (!to_throw.isEmpty() || !card_ids.isEmpty()) {
					dummy->addSubcards(to_throw + card_ids);
					CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, liuqi->objectName(), objectName(), QString());
					room->throwCard(dummy, reason, NULL);
				}
				delete dummy;
				room->clearAG();
			}
		}
		return false;
	}
};

//刘奇-奔波 
class Kaolao: public TriggerSkill {
public:
	Kaolao(): TriggerSkill("kaolao$") {
		events << TargetConfirmed << PreHpRecover;
		frequency = Compulsory;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL && target->hasLordSkill("kaolao");
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *sunquan, QVariant &data) const{
		if (triggerEvent == TargetConfirmed) {
			CardUseStruct use = data.value<CardUseStruct>();
			if (use.card->isKindOf("Peach") && use.from && use.from->getKingdom() == "yan"
				&& sunquan != use.from && sunquan->hasFlag("Global_Dying")) {
					room->setCardFlag(use.card, "kaolao");
			}
		} else if (triggerEvent == PreHpRecover) {
			RecoverStruct rec = data.value<RecoverStruct>();
			if (rec.card && rec.card->hasFlag("kaolao")) {
				if (sunquan->hasSkill("weidi"))
					room->broadcastSkillInvoke("weidi");
				else
					room->broadcastSkillInvoke("Kaolao", rec.who->isMale() ? 1 : 2);

				room->notifySkillInvoked(sunquan, "kaolao");

				LogMessage log;
				log.type = "#KaolaoExtraRecover";
				log.from = sunquan;
				log.to << rec.who;
				log.arg = objectName();
				room->sendLog(log);

				rec.recover++;
				data = QVariant::fromValue(rec);
			}
		}

		return false;
	}
};

//张新城-编码
class Bianma: public TriggerSkill{
public:
	Bianma(): TriggerSkill("bianma"){
		events<<Damaged;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* zhangxincheng,QVariant& data) const{
		DamageStruct damage = data.value<DamageStruct>();
		//if(!damage.card || damage.card->isVirtualCard()||!zhangxincheng->askForSkillInvoke(objectName(),data)) return false;
		const Card *card = damage.card;		
		if (card && room->getCardPlace(card->getEffectiveId()) == Player::PlaceTable 
			&& zhangxincheng->askForSkillInvoke(objectName(),data)) {
			QVariant data = QVariant::fromValue(card);
			foreach(int id,card->getSubcards()){
				zhangxincheng->addToPile("ma",id);
			}
		}
		return false;
	}
};

//张新城-编码，防止伤害
class BianmaDefend: public TriggerSkill{
public:
	BianmaDefend(): TriggerSkill("#bianma-defend"){
		events<<DamageInflicted<<EventLoseSkill<<Death;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room* room,ServerPlayer* zhangxingcheng,QVariant& data) const{
		if(triggerEvent == DamageInflicted){
			if(zhangxingcheng->getPile("ma").isEmpty()) return false;
			room->notifySkillInvoked(zhangxingcheng, "bianma");
			QList<int> cards = zhangxingcheng->getPile("ma");
			room->fillAG(cards,zhangxingcheng);
			int card_id = room->askForAG(zhangxingcheng,cards,false,"bianma");
			room->clearAG();
			LogMessage log1;
			log1.type = "#bianma";
			log1.from = zhangxingcheng;
			log1.arg = "bianma";
			room->sendLog(log1);
			if (card_id != -1) {
				CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "bianma", QString());
				room->throwCard(Sanguosha->getCard(card_id), reason, NULL);
				LogMessage log;
				log.type = "#BianmaDefend";
				log.from = zhangxingcheng;
				log.to<<data.value<DamageStruct>().from;
				room->sendLog(log);
				return true;
			}
		}else if(triggerEvent == EventLoseSkill && data.toString() == "bianma"){
			if(!zhangxingcheng->getPile("ma").isEmpty())
				zhangxingcheng->removePileByName("ma");
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == zhangxingcheng && !zhangxingcheng->getPile("ma").isEmpty())
				zhangxingcheng->removePileByName("ma");
		}		
		return false;
	}
};

//张新城-调试
class Tiaoshi: public TriggerSkill{
public:
	Tiaoshi(): TriggerSkill("tiaoshi"){
		events<<EventPhaseStart;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* zhangxincheng,QVariant& data) const{
		if(zhangxincheng->getPile("ma").isEmpty() || zhangxincheng->getPhase()!= Player::Finish) return false;
		int n = zhangxincheng->getPile("ma").length();
		LogMessage log;
		log.type = "#tiaoshi";
		log.from = zhangxincheng;
		log.arg = objectName();
		room->sendLog(log);
		room->notifySkillInvoked(zhangxincheng, objectName());
		zhangxincheng->removePileByName("ma");
		zhangxincheng->drawCards(n);
		return false;
	}
};

//骆雪芹--睡神
class Shuishen: public TriggerSkill{
public:
	Shuishen(): TriggerSkill("shuishen"){
		events<<EventPhaseStart;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* luoxueqin,QVariant& data) const{
		if(luoxueqin->getPhase() != Player::Start || !luoxueqin->askForSkillInvoke(objectName(),data)) return false;
		QString choice;
		if(!luoxueqin->isWounded())
			choice = "draw";
		else
			choice = room->askForChoice(luoxueqin,objectName(),"recover+draw",data);
		if(choice == "draw")
			luoxueqin->drawCards(2);
		else{
			RecoverStruct re;
			re.who = luoxueqin;
			room->recover(luoxueqin,re);
		}
		return false;
	}
};

//骆雪芹-时尚
class Shishang: public TriggerSkill{
public:
	Shishang(): TriggerSkill("shishang"){
		events<<DamageInflicted;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* player,QVariant& data) const{
		ServerPlayer *luoxueqin = room->findPlayerBySkillName(objectName());
		DamageStruct da = data.value<DamageStruct>();
		if(!luoxueqin || da.to == luoxueqin ||!luoxueqin->askForSkillInvoke(objectName(),data)) return false;		
		room->loseHp(luoxueqin);
		LogMessage log;
		log.type = "#shishang";
		log.from = da.to;
		log.arg = QString::number(da.damage);
		log.arg2 = QString::number(--da.damage);
		room->sendLog(log);
		data = QVariant::fromValue(da);
		luoxueqin->drawCards(1);
		if (da.damage < 1)
			return true;
		return false;
	}
};

//侯文洁-侯哥
class Houge: public OneCardViewAsSkill{
public:
	Houge(): OneCardViewAsSkill("houge"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player,"h");
	}

	virtual bool viewFilter(const Card *card) const{
		return card->isKindOf("EquipCard") && !card->isEquipped();
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		SavageAssault* card = new SavageAssault(originalCard->getSuit(), originalCard->getNumber());
		card->addSubcard(originalCard->getId());
		card->setSkillName(objectName());
		return card;
	}
};

//侯文洁-心宽
class Xinkuan: public TriggerSkill{
public:
	Xinkuan(): TriggerSkill("xinkuan"){
		events<<DamageCaused;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* houwenjie,QVariant& data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if(!damage.from || damage.from!=houwenjie) return false;
		if(!houwenjie->isWounded() && (damage.to->isNude() || !houwenjie->canDiscard(damage.to,"he"))) return false;
		if(!houwenjie->askForSkillInvoke(objectName(),data)) return false;
		QString choice;
		if(!houwenjie->isWounded())
			choice = "qipai";
		else if(damage.to->isNude())
			choice = "recover";
		else
			choice = room->askForChoice(houwenjie,objectName(),"qipai+recover",data);
		if(choice == "recover"){
			RecoverStruct re;
			re.who = houwenjie;
			room->recover(houwenjie,re);
		}else{
			if (houwenjie->canDiscard(damage.to, "he")) {
				int card_id = room->askForCardChosen(houwenjie, damage.to, "he", objectName(), false, Card::MethodDiscard);
				room->throwCard(Sanguosha->getCard(card_id), damage.to, houwenjie);

				if (houwenjie->isAlive() && damage.to->isAlive() && houwenjie->canDiscard(damage.to, "he")) {
					card_id = room->askForCardChosen(houwenjie, damage.to, "he", objectName(), false, Card::MethodDiscard);
					room->throwCard(Sanguosha->getCard(card_id), damage.to, houwenjie);
				}
			}
		}
		return true;
	}
};

//方孝健-随和
class Suihe:public TriggerSkill{
public:
	Suihe(): TriggerSkill("suihe"){
		events<<Damaged;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* fangxiaojian,QVariant& data) const{
		if(!fangxiaojian->isAlive() || !fangxiaojian->askForSkillInvoke(objectName(),data)) return false;
		fangxiaojian->drawCards(1);
		DamageStruct damage = data.value<DamageStruct>();
		if(damage.from && damage.from->isAlive() && !damage.from->isNude() && fangxiaojian->canDiscard(damage.from, "he")){
			int card_id = room->askForCardChosen(fangxiaojian, damage.from, "he", objectName(), false, Card::MethodDiscard);
			room->throwCard(Sanguosha->getCard(card_id), damage.from, fangxiaojian);
		}
		return false;
	}
};

//方孝健-机智
class JizhiFang: public OneCardViewAsSkill{
public:
	JizhiFang(): OneCardViewAsSkill("jizhi_fang"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player,"h");
	}

	virtual bool viewFilter(const Card *to_select) const{
		return to_select->getSuit() == Card::Club && !to_select->isEquipped();
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		Snatch *snatch = new Snatch(originalCard->getSuit(),originalCard->getNumber());
		snatch->setSkillName(objectName());
		snatch->addSubcard(originalCard->getId());
		return snatch;
	}
};

//熊焘-大神 
DashenCard::DashenCard(){
	target_fixed = true;
	will_throw = true;
	m_skillName = "dashen";
}

void DashenCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	source->throwAllHandCards();
	source->turnOver();
	QString choice = room->askForChoice(source,"dashen","recover+damageto");
	QList<ServerPlayer*>allpeople = room->getAllPlayers();
	QList<ServerPlayer*>others =room->getOtherPlayers(source);
	if(choice == "recover"){
		foreach(ServerPlayer* p,allpeople){
			RecoverStruct re;
			re.who = source;
			room->recover(p,re);
		}
		foreach (ServerPlayer *player, others) {
			if (player->isAlive() && !player->isAllNude()) {
				CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
				int card_id = room->askForCardChosen(source, player, "hej", objectName());
				room->obtainCard(source, Sanguosha->getCard(card_id),
					reason, room->getCardPlace(card_id) != Player::PlaceHand);
			}
		}
	}else{
		foreach(ServerPlayer* p,others){
			DamageStruct da;
			da.from = source;
			da.to = p;
			room->damage(da);
		}
		foreach(ServerPlayer* p,others){
			if(p->isAlive())
				p->drawCards(1);
		}
	}	
}

class Dashen: public ZeroCardViewAsSkill{
public:
	Dashen(): ZeroCardViewAsSkill("dashen"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return !player->isKongcheng() && player->canDiscard(player,"h") && !player->hasUsed("DashenCard");
	}

	virtual const Card *viewAs() const{
		return new DashenCard;
	}
};

//熊焘-强壮 
class Qiangzhuang: public DistanceSkill{
public:
	Qiangzhuang(): DistanceSkill("qiangzhuang"){
	}

	virtual int getCorrect(const Player *from, const Player *to) const{
		if(to->hasSkill(objectName()))
			return +1;
		else
			return 0;
	}
};

//刘从文--小资
class Xiaozi: public OneCardViewAsSkill{
public:
	Xiaozi(): OneCardViewAsSkill("xiaozi"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->isWounded() && !player->hasFlag("Global_PreventPeach") && player->canDiscard(player, "he");
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach")
			&& player->canDiscard(player, "he");
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		return selected.isEmpty() && to_select->isRed();
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		Peach *peach = new Peach(originalCard->getSuit(),originalCard->getNumber());
		peach->addSubcard(originalCard->getId());
		peach->setSkillName(objectName());
		return peach;
	}
};

//刘从文-奋斗
class Fendou: public FilterSkill{
public:
	Fendou(): FilterSkill("fendou"){
	}

	virtual bool viewFilter(const Card *to_select) const{
		Room *room = Sanguosha->currentRoom();
		Player::Place place = room->getCardPlace(to_select->getEffectiveId());
		return to_select->isKindOf("Jink") && place == Player::PlaceHand;
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		Slash *slash = new Slash(originalCard->getSuit(),originalCard->getNumber());
		slash->setSkillName(objectName());
		WrappedCard *card = Sanguosha->getWrappedCard(originalCard->getId());
		card->takeOver(slash);
		return card;
	}
};

//刘从文-从文
class Congwen: public TriggerSkill{
public:
	Congwen(): TriggerSkill("congwen"){
		events<<EventPhaseChanging;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		PhaseChangeStruct change = data.value<PhaseChangeStruct>();
		if(change.to != Player::Draw) return false;
		if(player->isSkipped(Player::Draw)) return false;
		if(!player->askForSkillInvoke(objectName(),data)) return false;
		player->skip(Player::Draw);
		player->gainMark("@congwen",2);
		return false;
	}
};

//免疫伤害
class CongwenDefend: public TriggerSkill{
public:
	CongwenDefend(): TriggerSkill("#congwen_defend"){
		events<<DamageInflicted<<EventPhaseStart<<EventLoseSkill<<Death;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(triggerEvent == DamageInflicted){			
			DamageStruct damage = data.value<DamageStruct>();
			if(damage.to!=player) return false;
			if(player->getMark("@congwen")==0) return false;
			player->loseMark("@congwen");
			LogMessage log;
			log.type = "#congwen";
			log.from = player;
			log.to<<(damage.from?damage.from:NULL);
			log.arg = QString::number(damage.damage);
			room->sendLog(log);
			return true;
		}else if(triggerEvent == EventPhaseStart){
			if(player->getPhase()!= Player::Start || player->getMark("@congwen")==0) return false;
			int n = player->getMark("@congwen");
			player->loseAllMarks("@congwen");
			if(player->isAlive())
				player->drawCards(n);
		}else if(triggerEvent == EventLoseSkill && data.toString() == "congwen"){
			if(player->getMark("@congwen")>0)
				player->loseAllMarks("@congwen");
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == player && player->getMark("@congwen")>0)
				player->loseAllMarks("@congwen");
		}
		return false;
	}
};

//何相良-羽神
class Yushen: public TargetModSkill{
public:
	Yushen(): TargetModSkill("yushen"){
	}

	virtual int getExtraTargetNum(const Player *from, const Card*) const{
		if(from->hasSkill(objectName()))
			return +1;
		else
			return 0;
	}

	virtual int getDistanceLimit(const Player *from, const Card *) const{
		if(from->hasSkill(objectName()))
			return +2;
		else
			return 0;
	}
};

//张晓龙-酒神
class Jiushen: public OneCardViewAsSkill {
public:
	Jiushen(): OneCardViewAsSkill("jiushen") {
		filter_pattern = ".|black|.|hand";
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return Analeptic::IsAvailable(player);
	}

	virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
		return  pattern.contains("analeptic");
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		Analeptic *analeptic = new Analeptic(originalCard->getSuit(), originalCard->getNumber());
		analeptic->setSkillName(objectName());
		analeptic->addSubcard(originalCard->getId());
		return analeptic;
	}
};

//张晓龙-表演
BiaoyanCard::BiaoyanCard(){
	will_throw = true;
	target_fixed = true;
	m_skillName = "biaoyan";
}

void BiaoyanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	room->showAllCards(source);
	if(source->getHandcardNum()>=3){
		RecoverStruct re;
		re.who = source;
		room->recover(source,re);
	}
}

class Biaoyan: public ZeroCardViewAsSkill{
public:
	Biaoyan(): ZeroCardViewAsSkill("biaoyan"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return !player->isKongcheng() && !player->hasUsed("BiaoyanCard");
	}

	virtual const Card* viewAs() const{
		return new BiaoyanCard;
	}
};

//姚云志-谦虚
QianxuCard::QianxuCard() {
	target_fixed = true;
	will_throw = true;
}

void QianxuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{	
	if (source->isAlive())
		room->drawCards(source, subcards.length());
}

class Qianxu: public ViewAsSkill {
public:
	Qianxu(): ViewAsSkill("qianxu") {
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{		
		return !Self->isJilei(to_select);
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.isEmpty())
			return NULL;

		QianxuCard *card = new QianxuCard;
		card->addSubcards(cards);
		card->setSkillName(objectName());
		return card;
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player, "he") && !player->hasUsed("QianxuCard");
	}
};

//张洪昌-收藏
class Shoucang: public TriggerSkill{
public:
	Shoucang(): TriggerSkill("shoucang"){
		events<<BeforeCardsMove;
		//frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *caozhi, QVariant &data) const{
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from == caozhi || move.from == NULL)
			return false;
		if (move.to_place == Player::DiscardPile
			&& ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)) {
				QList<int> card_ids;
				int i = 0;
				foreach (int card_id, move.card_ids) {
					if (Sanguosha->getCard(card_id)->getTypeId() == Card::TypeBasic						
						&& room->getCardOwner(card_id) == move.from
						&& (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip))
						card_ids << card_id;
					i++;
				}
				if (card_ids.empty())
					return false;
				else if (caozhi->askForSkillInvoke(objectName(), data)) {					
					while (!card_ids.empty()) {
						room->fillAG(card_ids, caozhi);
						int id = room->askForAG(caozhi, card_ids, true, objectName());
						if (id == -1) {
							room->clearAG(caozhi);
							break;
						}
						card_ids.removeOne(id);
						room->clearAG(caozhi);
					}
					if (!card_ids.empty()) {
						//room->broadcastSkillInvoke("shoucang");
						foreach (int id, card_ids) {
							if (move.card_ids.contains(id)) {
								move.from_places.removeAt(move.card_ids.indexOf(id));
								move.card_ids.removeOne(id);
								data = QVariant::fromValue(move);
							}
							room->moveCardTo(Sanguosha->getCard(id), caozhi, Player::PlaceHand, move.reason, true);
							if (!caozhi->isAlive())
								break;
						}
					}
				}
		}
		return false;
	}
};

//张洪昌-劝酒
class Quanjiu: public TriggerSkill{
public:
	Quanjiu(): TriggerSkill("quanjiu"){
		events<<EventPhaseStart;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(player->getPhase() != Player::Play || player->isKongcheng()) return false;
		ServerPlayer *zhanghongchang = room->findPlayerBySkillName(objectName());
		if(!zhanghongchang->canDiscard(player,"h") || !zhanghongchang->askForSkillInvoke(objectName())) return false;
		if(player!=zhanghongchang){
			int card_id = room->askForCardChosen(zhanghongchang,player,"h",objectName(),false,Card::MethodDiscard);
			room->throwCard(Sanguosha->getCard(card_id), player,zhanghongchang);
			Analeptic *analeptic = new Analeptic(Card::NoSuit,0);
			//analeptic->setSkillName(objectName());
			room->useCard(CardUseStruct(analeptic, player, player));
		}else{
			if(zhanghongchang->canDiscard(zhanghongchang,"h") && room->askForDiscard(zhanghongchang,objectName(),1,1,false,false,"#quanjiu")){
				Analeptic *analeptic = new Analeptic(Card::NoSuit,0);
				//analeptic->setSkillName(objectName());
				room->useCard(CardUseStruct(analeptic, player, player));
			}
		}
		return false;
	}
};

//张洪昌-宣讲
XuanjiangCard::XuanjiangCard() {
	will_throw = false;
	mute = true;
	handling_method = Card::MethodNone;
}

bool XuanjiangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select->getKingdom() == "yan" && to_select != Self;
}

void XuanjiangCard::onEffect(const CardEffectStruct &effect) const{
	Room *room = effect.to->getRoom();
	ServerPlayer *player = effect.from, *victim = effect.to;
	room->removePlayerMark(player, "@xuan");
	room->setPlayerMark(player, "xhate", 1);
	victim->gainMark("@xuan_to");
	room->setPlayerMark(victim, "xuan_" + player->objectName(), 1);

	CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName());
	reason.m_playerId = victim->objectName();
	room->obtainCard(victim, this, reason, false);
}

class XuanjiangViewAsSkill: public ViewAsSkill {
public:
	XuanjiangViewAsSkill(): ViewAsSkill("xuanjiang") {
		response_pattern = "@@xuanjiang";
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *) const{
		return selected.length() < 2;
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.length() != 2)
			return NULL;

		XuanjiangCard *card = new XuanjiangCard;
		card->addSubcards(cards);
		return card;
	}
};

class Xuanjiang: public TriggerSkill {
public:
	Xuanjiang(): TriggerSkill("xuanjiang$") {
		events << EventPhaseStart << DamageInflicted << Dying;
		frequency = Limited;
		limit_mark = "@xuan";
		view_as_skill = new XuanjiangViewAsSkill;
	}

	virtual bool triggerable(const ServerPlayer *player) const{
		return player != NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if (triggerEvent == EventPhaseStart && player->getMark("xhate") == 0 && player->hasLordSkill("xuanjiang")
			&& player->getPhase() == Player::Start && player->getCards("he").length() > 1) {
				foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
					if (p->getKingdom() == "yan") {
						room->askForUseCard(player, "@@xuanjiang", "@xuanjiang-give", -1, Card::MethodNone);
						break;
					}
				}
		} else if (triggerEvent == DamageInflicted && player->hasLordSkill(objectName()) && player->getMark("XuanjiangTarget") == 0) {
			ServerPlayer *target = NULL;
			foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
				if (p->getMark("xuan_" + player->objectName()) > 0 && p->getMark("@xuan_to") > 0) {
					target = p;
					break;
				}
			}
			if (target == NULL || target->isDead())
				return false;
			LogMessage log;
			log.type = "#XuanjiangProtect";
			log.arg = objectName();
			log.from = player;
			log.to << target;
			room->sendLog(log);
			DamageStruct damage = data.value<DamageStruct>();

			if (damage.card && damage.card->isKindOf("Slash")) {
				player->removeQinggangTag(damage.card);
			}

			DamageStruct newdamage = damage;
			newdamage.to = target;
			newdamage.transfer = true;

			target->addMark("XuanjiangTarget");
			try {
				room->damage(newdamage);
			}
			catch (TriggerEvent triggerEvent) {
				if (triggerEvent == TurnBroken || triggerEvent == StageChange)
					target->removeMark("XuanjiangTarget");
				throw triggerEvent;
			}
			return true;
		} else if (triggerEvent == Dying) {
			DyingStruct dying = data.value<DyingStruct>();
			if (dying.who != player)
				return false;
			if (player->getMark("@xuan_to") > 0)
				player->loseAllMarks("@xuan_to");
		}
		return false;
	}
};

class XuanjiangDraw: public TriggerSkill {
public:
	XuanjiangDraw(): TriggerSkill("#xuanjiang") {
		events << DamageComplete;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if (player->isAlive() && player->getMark("XuanjiangTarget") > 0 && damage.transfer) {
			player->drawCards(damage.damage);
			player->removeMark("XuanjiangTarget");
		}

		return false;
	}
};

//王湘淋-爱笑
class Aixiao: public TriggerSkill{
public:
	Aixiao(): TriggerSkill("aixiao"){
		events<<CardAsked;
		frequency = Frequent;
	}	

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		QString pattern = data.toStringList().first();		
		if(pattern!="jink") return false;		
		if(!player->askForSkillInvoke(objectName(),data)) return false;
		JudgeStruct judge;
		judge.pattern = ".|red";
		judge.reason = objectName();
		judge.who = player;
		judge.good = true;
		room->judge(judge);
		if(judge.isGood()){
			Jink *jink = new Jink(Card::NoSuit,0);
			jink->setSkillName(objectName());
			room->provide(jink);
			return true;
		}
		return false;
	}
};

//王湘淋-厨艺
ChuyiCard::ChuyiCard() {
}

bool ChuyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select->isWounded();
}

bool ChuyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
	return targets.value(0, Self)->isWounded();
}

void ChuyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	ServerPlayer *target = targets.value(0, source);

	CardEffectStruct effect;
	effect.card = this;
	effect.from = source;
	effect.to = target;

	room->cardEffect(effect);
}

void ChuyiCard::onEffect(const CardEffectStruct &effect) const{
	RecoverStruct recover;
	recover.card = this;
	recover.who = effect.from;
	effect.to->getRoom()->recover(effect.to, recover);
}

class Chuyi: public OneCardViewAsSkill {
public:
	Chuyi(): OneCardViewAsSkill("chuyi") {	
		filter_pattern = ".|.";
	}
		
	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player, "he") && !player->hasUsed("ChuyiCard");
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		ChuyiCard *qingnang_card = new ChuyiCard;
		qingnang_card->addSubcard(originalCard->getId());
		qingnang_card->setSkillName(objectName());
		return qingnang_card;
	}
};

//杨浩-游戏 
//YouxiCard::YouxiCard() {
//	mute = true;
//}
//
//bool YouxiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
//	Slash *slash = new Slash(NoSuit, 0);
//	slash->setSkillName("youxi");
//	slash->deleteLater();
//	return targets.isEmpty() && Self->canSlash(to_select, slash, false);
//}
//
//void YouxiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
//	foreach (ServerPlayer *target, targets) {
//		if (!source->canSlash(target, NULL, false))
//			targets.removeOne(target);
//	}
//
//	if (targets.length() > 0) {
//		Slash *slash = new Slash(Card::NoSuit, 0);
//		slash->setSkillName("youxi");
//		room->useCard(CardUseStruct(slash, source, targets));
//	}
//}
//
//class YouxiViewAsSkill: public ZeroCardViewAsSkill {
//public:
//	YouxiViewAsSkill(): ZeroCardViewAsSkill("youxi") {
//		response_pattern = "@@youxi";
//	}
//
//	virtual const Card *viewAs() const{
//		return new YouxiCard;
//	}
//};

class Youxi: public TriggerSkill {
public:
	Youxi(): TriggerSkill("youxi") {
		events << EventPhaseChanging;
		//view_as_skill = new YouxiViewAsSkill;
	}

	virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const{
		PhaseChangeStruct change = data.value<PhaseChangeStruct>();
		QList<ServerPlayer*> targets;
		foreach(ServerPlayer* p,room->getOtherPlayers(player)){
			Slash *slash = new Slash(Card::NoSuit, 0);
			//slash->setSkillName("youxi");
			slash->deleteLater();
			if(player->canSlash(p,slash,false))
				targets<<p;
		}
		if(targets.isEmpty()) return false;
		if (change.to == Player::Judge && !player->isSkipped(Player::Judge)
			&& !player->isSkipped(Player::Draw) && room->askForSkillInvoke(player,objectName(),data)) {
			ServerPlayer* target = room->askForPlayerChosen(player,targets,objectName(),"#youxi");
			Slash* slash = new Slash(Card::NoSuit,0);
			//slash->setSkillName("youxi");
			CardUseStruct carduse;
			carduse.from = player;
			carduse.card = slash;
			carduse.to<<target;
			room->useCard(carduse,false);
			player->skip(Player::Judge);
			player->skip(Player::Draw);				
		}
		return false;
	}
};

//杨浩-游泳 
class Youyong: public TriggerSkill {
public:
	Youyong(): TriggerSkill("youyong") {
		events << DamageInflicted;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if (damage.nature == DamageStruct::Fire) {
			room->notifySkillInvoked(player, objectName());
			//room->broadcastSkillInvoke(objectName());
			LogMessage log;
			log.type = "#YouyongProtect";
			log.from = player;
			log.arg = QString::number(damage.damage);
			log.arg2 = "fire_nature";
			room->sendLog(log);
			return true;
		}
		return false;
	}
};

//田显钊-隐忍
class Yinren: public TriggerSkill {
public:
	Yinren(): TriggerSkill("yinren") {
		events << PreCardUsed << CardResponded << EventPhaseChanging;
		frequency = Frequent;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *lvmeng, QVariant &data) const{
		if (triggerEvent == EventPhaseChanging) {
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if (change.to == Player::Discard && TriggerSkill::triggerable(lvmeng)) {
				if (!lvmeng->hasFlag("KejiSlashInPlayPhase") && lvmeng->askForSkillInvoke(objectName())) {					
					lvmeng->skip(Player::Discard);
				}
			}
			if (change.to == Player::NotActive && lvmeng->hasFlag("KejiSlashInPlayPhase"))
				lvmeng->setFlags("-KejiSlashInPlayPhase");
		} else if (lvmeng->getPhase() == Player::Play) {
			CardStar card = NULL;
			if (triggerEvent == PreCardUsed)
				card = data.value<CardUseStruct>().card;
			else
				card = data.value<CardResponseStruct>().m_card;
			if (card->isKindOf("Slash"))
				lvmeng->setFlags("KejiSlashInPlayPhase");
		}
		return false;
	}
};

//田显钊-维护
class Weihu: public TriggerSkill {
public:
	Weihu(): TriggerSkill("weihu") {
		events << CardsMoveOneTime;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *sunshangxiang, QVariant &data) const{
		if(sunshangxiang->getPhase() != Player::NotActive) return false;
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from == sunshangxiang && move.from_places.contains(Player::PlaceHand) &&
			move.to_place == Player::DiscardPile) {
			for (int i = 0; i < move.card_ids.size(); i++) {
				if (!sunshangxiang->isAlive())
					return false;
				if (move.from_places[i] == Player::PlaceHand) {
					const Card* card = Sanguosha->getCard(move.card_ids[i]);
					if(!card->isKindOf("Jink")) continue;
					if (room->askForSkillInvoke(sunshangxiang, objectName(),data)) {
						//room->broadcastSkillInvoke(objectName());
						sunshangxiang->drawCards(1);
					} else {
						break;
					}
				}
			}
		}
		return false;
	}
};



//------------------二楼平台组-------------------------
//陆伟-土豪
TuhaoCard::TuhaoCard(){
	m_skillName = "tuhao";
	will_throw = true;
	target_fixed = true;
}

void TuhaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	if(source->isAlive())
		source->drawCards(2*subcards.length());
}

class Tuhao: public ViewAsSkill {
public:
	Tuhao(): ViewAsSkill("tuhao") {
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{		
		return !Self->isJilei(to_select) && selected.length()<2 && to_select->isRed() && !to_select->isEquipped();
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.isEmpty())
			return NULL;

		TuhaoCard *Tuhao_card = new TuhaoCard;
		Tuhao_card->addSubcards(cards);
		Tuhao_card->setSkillName(objectName());
		return Tuhao_card;
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player, "h") && !player->hasUsed("TuhaoCard");
	}	
};

//陆伟-飞车
class Feiche: public DistanceSkill{
public:
	Feiche(): DistanceSkill("feiche"){
	}

	virtual int getCorrect(const Player *from, const Player *to) const{
		if (from->hasSkill(objectName()))
			return -1;
		else if (to->hasSkill(objectName()))
			return +1;
		else
			return 0;
	}
}; 

//赵祖乾-酱油
class Jiangyou: public TriggerSkill{
public:
	Jiangyou(): TriggerSkill("jiangyou"){
		events<<EventPhaseChanging;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* zhaozuqian,QVariant &data) const{
		PhaseChangeStruct change = data.value<PhaseChangeStruct>();
		if(change.to != Player::Play || zhaozuqian->isSkipped(Player::Play)) return false;
		if(zhaozuqian->askForSkillInvoke(objectName(),data)){
			zhaozuqian->skip(Player::Play);
			QList<ServerPlayer*>targets;
			foreach(ServerPlayer* player,room->getOtherPlayers(zhaozuqian)){
				if(!player->isKongcheng())
					targets<<player;
			}
			ServerPlayer *target = room->askForPlayerChosen(zhaozuqian,targets,objectName(),"#jiangyou");
			QList<int> ids;
			foreach(const Card* card,target->getHandcards()){
				ids<<card->getId();
			}
			CardsMoveStruct move;
			move.card_ids = ids;
			move.to = zhaozuqian;
			move.to_place = Player::PlaceHand;
			room->moveCards(move,false);
		}
		return false;
	}
};

//赵祖乾-影帝
class Yingdi: public TriggerSkill{
public:
	Yingdi(): TriggerSkill("yingdi"){
		events<<CardEffected;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* zhaozuqian,QVariant &data) const{
		CardEffectStruct card = data.value<CardEffectStruct>();
		if(!(card.card->isKindOf("Slash") || card.card->isKindOf("Duel")) || card.to != zhaozuqian) return false;
		if(zhaozuqian->askForSkillInvoke(objectName(),data)){
			JudgeStruct judge;
			judge.pattern = ".|red";
			judge.reason = objectName();
			judge.who = zhaozuqian;
			judge.good = true;
			room->judge(judge);
			if(judge.isGood()){
				LogMessage log;
				log.type = "#yingdi";
				log.from = card.from;
				log.to << zhaozuqian;
				log.arg = card.card->objectName();				
				room->sendLog(log);
				return true;
			}
			return false;
		}
		return false;
	}
};

//赵祖乾-嘚瑟
class Dese: public MaxCardsSkill {
public:
	Dese(): MaxCardsSkill("dese") {
	}

	virtual int getExtra(const Player *target) const{
		if (target->hasSkill(objectName())) {			
			return 2;
		} else
			return 0;
	}
};

//郭瑞敏-女总
NvzongCard::NvzongCard() {
	will_throw = false;
	handling_method = Card::MethodNone;
}

bool NvzongCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	if (!targets.isEmpty() || to_select == Self)
		return false;

	const Card *card = Sanguosha->getCard(subcards.first());
	const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
	int equip_index = static_cast<int>(equip->location());
	return to_select->getEquip(equip_index) == NULL;
}

void NvzongCard::onEffect(const CardEffectStruct &effect) const{
	ServerPlayer *guoruimin = effect.from;
	guoruimin->getRoom()->moveCardTo(this, guoruimin, effect.to, Player::PlaceEquip,
		CardMoveReason(CardMoveReason::S_REASON_PUT,
		guoruimin->objectName(), "Nvzong", QString()));

	LogMessage log;
	log.type = "$NvzongEquip";
	log.from = effect.to;
	log.card_str = QString::number(effect.card->getEffectiveId());
	guoruimin->getRoom()->sendLog(log);
	guoruimin->drawCards(1);
}

class Nvzong: public OneCardViewAsSkill {
public:
	Nvzong():OneCardViewAsSkill("nvzong") {
		filter_pattern = "EquipCard|.|.|hand";
	}
	
	virtual const Card *viewAs(const Card *originalCard) const{
		NvzongCard *Nvzong_card = new NvzongCard();
		Nvzong_card->addSubcard(originalCard);
		return Nvzong_card;
	}
};

//郭瑞敏-大姐
class Dajie: public TriggerSkill {
public:
	Dajie(): TriggerSkill("dajie") {
		events << CardsMoveOneTime;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(player->isKongcheng() || !player->canDiscard(player,"h")) return false;
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from && move.from->isAlive() && move.from_places.contains(Player::PlaceHand)
			&& ((move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE
			&& move.reason.m_playerId != move.reason.m_targetId)
			|| ((move.to_place == Player::PlaceTable && move.origin_to && move.origin_to != move.from && move.origin_to_place == Player::PlaceHand)
			|| (move.to && move.to != move.from && move.to_place == Player::PlaceHand)))) {
				if (room->askForSkillInvoke(player, objectName(), data)) {
					if(room->askForDiscard(player,objectName(),1,1,false,false,"#dajie")){
						if (move.from->isAlive())
							room->drawCards((ServerPlayer *)move.from, 2);
					}
				}
		}
		return false;
	}
};

//韩璐-打包
class Dabao: public TriggerSkill{
public:
	Dabao(): TriggerSkill("dabao"){
		events<<SlashMissed;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* hanlu,QVariant& data) const{
		SlashEffectStruct effect = data.value<SlashEffectStruct>();
		if(effect.from!=hanlu || !hanlu->isAlive() ||effect.slash->isVirtualCard()) return false;
		if(hanlu->getPile("bao").length()>=3) return false;
		if(!hanlu->askForSkillInvoke(objectName(),data)) return false;
		hanlu->addToPile("bao",effect.slash->getId());
		if(!effect.jink->isVirtualCard())
			hanlu->addToPile("bao",effect.jink->getId());
		return false;
	}
};

//韩璐-打包距离
class DabaoDistance: public DistanceSkill{
public:
	DabaoDistance(): DistanceSkill("#dabao-distance"){
	}

	virtual int getCorrect(const Player *from, const Player *to) const{
		if (to->hasSkill(objectName()))
			return to->getPile("bao").length();
		else
			return 0;
	}
}; 

//打包-清除 
class DabaoClear: public TriggerSkill{
public:
	DabaoClear(): TriggerSkill("#dabao-clear"){
		events<<Death<<EventLoseSkill<<EventPhaseStart;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(triggerEvent == EventLoseSkill){
			if(data.toString() == "dabao")
				player->removePileByName("bao");
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == player)
				player->removePileByName("bao");
		}else if(triggerEvent == EventPhaseStart){
			if(player->getPhase()!= Player::Start) return false;
			if(player->getPile("bao").isEmpty()) return false;
			int n =player->getPile("bao").length();
			player->removePileByName("bao");
			if(player->isAlive())
				player->drawCards(n);
		}
		return false;
	}
};

//韩璐-发布
FabuCard::FabuCard(){
	target_fixed = true;
	will_throw = true;
	m_skillName = "fabu";
}

void FabuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	QList<int> cards = source->getPile("bao");
	room->fillAG(cards, source);
	int card_id = room->askForAG(source, cards, false, "fabu");
	room->clearAG();
	if (card_id != -1) {
		CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "fabu", QString());
		room->throwCard(Sanguosha->getCard(card_id), reason, NULL);
		AmazingGrace *amazing_grace = new AmazingGrace(Card::SuitToBeDecided,-1);
		room->useCard(CardUseStruct(amazing_grace, source, targets));
	}
}

class Fabu: public ZeroCardViewAsSkill {
public:
	Fabu(): ZeroCardViewAsSkill("fabu") {
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		if (player->getPile("bao").isEmpty())
			return false;
		return true;
	}
	
	virtual const Card *viewAs() const{
		return new FabuCard;
	}
};

//张和华-研发
class Yanfa: public OneCardViewAsSkill{
public:
	Yanfa(): OneCardViewAsSkill("yanfa"){		
	}

	virtual bool viewFilter(const Card *to_select) const{
		return !Self->isJilei(to_select) && to_select->isKindOf("EquipCard");
	}

	virtual const Card* viewAs(const Card *originalCard) const{		
		if(originalCard->isKindOf("Weapon")){
			AmazingGrace* card = new AmazingGrace(originalCard->getSuit(),originalCard->getNumber());
			card->setSkillName(objectName());
			card->addSubcard(originalCard);
			return card;
		}else if(originalCard->isKindOf("Armor")){
			GodSalvation* card = new GodSalvation(originalCard->getSuit(),originalCard->getNumber());
			card->setSkillName(objectName());
			card->addSubcard(originalCard);
			return card;
		}else if(originalCard->isKindOf("DefensiveHorse")){
			SavageAssault* card = new SavageAssault(originalCard->getSuit(),originalCard->getNumber());
			card->setSkillName(objectName());
			card->addSubcard(originalCard);
			return card;
		}else if(originalCard->isKindOf("OffensiveHorse")){
			ArcheryAttack* card = new ArcheryAttack(originalCard->getSuit(),originalCard->getNumber());
			card->setSkillName(objectName());
			card->addSubcard(originalCard);
			return card;
		}else			
			return NULL;
	}
};

//张和华-集错
class Jicuo: public TriggerSkill{
public:
	Jicuo(): TriggerSkill("jicuo"){
		events<<BeforeCardsMove;
		//frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *caozhi, QVariant &data) const{
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from == caozhi || move.from == NULL)
			return false;
		if (move.to_place == Player::DiscardPile
			&& ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD
			||move.reason.m_reason == CardMoveReason::S_REASON_JUDGEDONE)) {
				QList<int> card_ids;
				int i = 0;
				foreach (int card_id, move.card_ids) {
					if (Sanguosha->getCard(card_id)->isKindOf("EquipCard")
						&& ((move.reason.m_reason == CardMoveReason::S_REASON_JUDGEDONE
						&& move.from_places[i] == Player::PlaceJudge
						&& move.to_place == Player::DiscardPile)
						|| (move.reason.m_reason != CardMoveReason::S_REASON_JUDGEDONE
						&& room->getCardOwner(card_id) == move.from
						&& (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip))))
						card_ids << card_id;
					i++;
				}
				if (card_ids.empty())
					return false;
				else if (caozhi->askForSkillInvoke(objectName(), data)) {					
					while (!card_ids.empty()) {
						room->fillAG(card_ids, caozhi);
						int id = room->askForAG(caozhi, card_ids, true, objectName());
						if (id == -1) {
							room->clearAG(caozhi);
							break;
						}
						card_ids.removeOne(id);
						room->clearAG(caozhi);
					}
					if (!card_ids.empty()) {
						//room->broadcastSkillInvoke("jicuo");
						foreach (int id, card_ids) {
							if (move.card_ids.contains(id)) {
								move.from_places.removeAt(move.card_ids.indexOf(id));
								move.card_ids.removeOne(id);
								data = QVariant::fromValue(move);
							}
							room->moveCardTo(Sanguosha->getCard(id), caozhi, Player::PlaceHand, move.reason, true);
							if (!caozhi->isAlive())
								break;
						}
					}
				}
		}
		return false;
	}
};

//张和华-收集
ShoujiCard::ShoujiCard() {
	will_throw = false;
	handling_method = Card::MethodNone;
	m_skillName = "shoujiv";
	mute = true;
}

void ShoujiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	ServerPlayer *zhanghehua = targets.first();
	if (zhanghehua->hasLordSkill("shouji")) {
		room->setPlayerFlag(zhanghehua, "ShoujiInvoked");
		room->notifySkillInvoked(zhanghehua, "shouji");
		zhanghehua->obtainCard(this);
		QList<ServerPlayer *> zhanghehuas;
		QList<ServerPlayer *> players = room->getOtherPlayers(source);
		foreach (ServerPlayer *p, players) {
			if (p->hasLordSkill("shouji") && !p->hasFlag("ShoujiInvoked"))
				zhanghehuas << p;
		}
		if (zhanghehuas.empty())
			room->setPlayerFlag(source, "ForbidShouji");
	}
}

bool ShoujiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select->hasLordSkill("shouji")
		&& to_select != Self && !to_select->hasFlag("ShoujiInvoked");
}

class ShoujiViewAsSkill: public OneCardViewAsSkill {
public:
	ShoujiViewAsSkill():OneCardViewAsSkill("shoujiv") {
		attached_lord_skill = true;
		filter_pattern = "EquipCard";
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->getKingdom() == "ping" && !player->hasFlag("ForbidShouji");
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		ShoujiCard *card = new ShoujiCard;
		card->addSubcard(originalCard);

		return card;
	}
};

class Shouji: public TriggerSkill {
public:
	Shouji(): TriggerSkill("shouji$") {
		events << GameStart << EventAcquireSkill << EventLoseSkill << EventPhaseChanging;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if ((triggerEvent == GameStart && player->isLord())
			|| (triggerEvent == EventAcquireSkill && data.toString() == "shouji")) {
				QList<ServerPlayer *> lords;
				foreach (ServerPlayer *p, room->getAlivePlayers()) {
					if (p->hasLordSkill(objectName()))
						lords << p;
				}
				if (lords.isEmpty()) return false;

				QList<ServerPlayer *> players;
				if (lords.length() > 1)
					players = room->getAlivePlayers();
				else
					players = room->getOtherPlayers(lords.first());
				foreach (ServerPlayer *p, players) {
					if (!p->hasSkill("shoujiv"))
						room->attachSkillToPlayer(p, "shoujiv");
				}
		} else if (triggerEvent == EventLoseSkill && data.toString() == "shouji") {
			QList<ServerPlayer *> lords;
			foreach (ServerPlayer *p, room->getAlivePlayers()) {
				if (p->hasLordSkill(objectName()))
					lords << p;
			}
			if (lords.length() > 2) return false;

			QList<ServerPlayer *> players;
			if (lords.isEmpty())
				players = room->getAlivePlayers();
			else
				players << lords.first();
			foreach (ServerPlayer *p, players) {
				if (p->hasSkill("shoujiv"))
					room->detachSkillFromPlayer(p, "shoujiv", true);
			}
		} else if (triggerEvent == EventPhaseChanging) {
			PhaseChangeStruct phase_change = data.value<PhaseChangeStruct>();
			if (phase_change.from != Player::Play)
				return false;
			if (player->hasFlag("ForbidShouji"))
				room->setPlayerFlag(player, "-ForbidShouji");
			QList<ServerPlayer *> players = room->getOtherPlayers(player);
			foreach (ServerPlayer *p, players) {
				if (p->hasFlag("ShoujiInvoked"))
					room->setPlayerFlag(p, "-ShoujiInvoked");
			}
		}
		return false;
	}
};

//郭俊峰-纠错
class Jiucuo: public TriggerSkill{
public:
	Jiucuo(): TriggerSkill("jiucuo"){
		events << HpChanged << CardsMoveOneTime << EventPhaseChanging;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room* room,ServerPlayer* guojunfeng,QVariant& data) const{
		int hp = guojunfeng->getHp();
		if (triggerEvent == CardsMoveOneTime) {
			CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
			if (guojunfeng->getPhase() == Player::Discard) {
				bool changed = false;
				if (move.from == guojunfeng && move.from_places.contains(Player::PlaceHand))
					changed = true;
				if (move.to == guojunfeng && move.to_place == Player::PlaceHand)
					changed = true;
				if (changed)
					guojunfeng->addMark("jiucuo");
				return false;
			} else {
				bool can_invoke = false;
				if (move.from == guojunfeng && move.from_places.contains(Player::PlaceHand))
					can_invoke = true;
				if (move.to == guojunfeng && move.to_place == Player::PlaceHand)
					can_invoke = true;
				if (!can_invoke)
					return false;
			}
		} else if (triggerEvent == HpChanged) {
			if (guojunfeng->getPhase() == Player::Discard) {
				guojunfeng->addMark("jiucuo");
				return false;
			}
		} else if (triggerEvent == EventPhaseChanging) {
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if (change.from != Player::Discard)
				return false;
			if (guojunfeng->getMark("jiucuo") <= 0)
				return false;
			guojunfeng->setMark("jiucuo", 0);
		}

		if (guojunfeng->getHandcardNum()<hp && guojunfeng->getPhase() != Player::Discard
			&& guojunfeng->askForSkillInvoke(objectName())) {
				guojunfeng->drawCards(hp - guojunfeng->getHandcardNum());
				room->broadcastSkillInvoke(objectName());
		}
		return false;
	}
};

//郭俊峰-禅道
class Chandao: public TriggerSkill{
public:
	Chandao(): TriggerSkill("chandao"){
		events<<TargetConfirming;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* guojunfeng,QVariant &data) const{
		CardUseStruct effect = data.value<CardUseStruct>();
		if(!effect.to.contains(guojunfeng) || effect.from == guojunfeng ||!effect.card->isNDTrick()
			||!guojunfeng->askForSkillInvoke(objectName(),data)) return false;
		QString choice;
		room->setTag("guojunfeng",QVariant::fromValue(guojunfeng));
		if(effect.from->isNude())
			choice = "letdraw";
		else
			choice = room->askForChoice(effect.from,objectName(),"discardone+letdraw",data);
		if(choice == "discardone")
			room->askForDiscard(effect.from,objectName(),1,1,false,true,"#discardone");
		else{
			if(guojunfeng->isAlive())
				guojunfeng->drawCards(1);
		}
		room->removeTag("guojunfeng");
		return false;
	}
};

//郭俊峰-帮扶要闪
class BangfuAsk: public TriggerSkill{
public:
	BangfuAsk(): TriggerSkill("bangfuask"){
		events<<CardAsked;		
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->getKingdom() == "ping";
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer* player,QVariant& data) const{
		if(player->getKingdom()!="ping") return false;
		QString pattern = data.toStringList().first();
		QString prompt = data.toStringList().at(1);
		if (pattern != "jink" || prompt.startsWith("@bangfuask"))
			return false;
		QList<ServerPlayer *> caopis;
		foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
			if (p->hasLordSkill("bangfu"))
				caopis << p;
		}
		if(caopis.isEmpty() || !player->askForSkillInvoke(objectName(),data)) return false;
		QVariant tohelp = QVariant::fromValue((PlayerStar)player);
		room->setTag("tohelp",tohelp);
		foreach(ServerPlayer* p,caopis){			
			const Card *jink = room->askForCard(p,"jink","@bangfuask:"+player->objectName(),tohelp,
				Card::MethodResponse,player,false,QString(),true);
			if (jink) {
				room->provide(jink);
				if(p->isAlive())
					p->drawCards(1);
				room->removeTag("tohelp");
				return true;
			}
		}
		room->removeTag("tohelp");
		return false;
	}
};

//郭俊峰-帮扶分配技能
class Bangfu: public TriggerSkill{
public:
	Bangfu(): TriggerSkill("bangfu$"){
		events<<GameStart<< EventAcquireSkill << EventLoseSkill;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if ((triggerEvent == GameStart && player->isLord())
			|| (triggerEvent == EventAcquireSkill && data.toString() == "bangfu")) {
				QList<ServerPlayer *> lords;
				foreach (ServerPlayer *p, room->getAlivePlayers()) {
					if (p->hasLordSkill(objectName()))
						lords << p;
				}
				if (lords.isEmpty()) return false;

				QList<ServerPlayer *> players;
				if (lords.length() > 1)
					players = room->getAlivePlayers();
				else
					players = room->getOtherPlayers(lords.first());
				foreach (ServerPlayer *p, players) {
					if (!p->hasSkill("bangfuask"))
						room->attachSkillToPlayer(p, "bangfuask");
				}
		} else if (triggerEvent == EventLoseSkill && data.toString() == "bangfu") {
			QList<ServerPlayer *> lords;
			foreach (ServerPlayer *p, room->getAlivePlayers()) {
				if (p->hasLordSkill(objectName()))
					lords << p;
			}
			if (lords.length() > 2) return false;

			QList<ServerPlayer *> players;
			if (lords.isEmpty())
				players = room->getAlivePlayers();
			else
				players << lords.first();
			foreach (ServerPlayer *p, players) {
				if (p->hasSkill("bangfuask"))
					room->detachSkillFromPlayer(p, "bangfuask", true);
			}
		} 
		return false;
	}
};

//周磊-测试 
class Ceshi: public TriggerSkill {
public:
	Ceshi(): TriggerSkill("ceshi") {
		events << DamageCaused;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if (damage.chain || damage.transfer || !damage.by_user) return false;
		if (damage.from && !damage.to->inMyAttackRange(damage.from)
			&& damage.card && damage.card->isKindOf("Slash")) {
				room->broadcastSkillInvoke(objectName());
				room->notifySkillInvoked(damage.from, objectName());

				LogMessage log;
				log.type = "#CeshiBuff";
				log.from = damage.from;
				log.to << damage.to;
				log.arg = QString::number(damage.damage);
				log.arg2 = QString::number(++damage.damage);
				room->sendLog(log);

				data = QVariant::fromValue(damage);
		}

		return false;
	}
};

//汪玲-吃货 
class Chihuo: public DrawCardsSkill{
public:
	Chihuo(): DrawCardsSkill("chihuo"){
		frequency = Frequent;
	}

	virtual int getDrawNum(ServerPlayer *player, int n) const{
		if(player->askForSkillInvoke(objectName()))
			return n+1;
		else
			return n;
	}
};

//汪玲-不安 
class Buan: public TriggerSkill{
public:
	Buan(): TriggerSkill("buan"){
		events<<SlashMissed;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *pangde, QVariant &data) const{
		SlashEffectStruct effect = data.value<SlashEffectStruct>();
		if (effect.to->isAlive() && pangde->canDiscard(effect.to, "he")) {
			if (pangde->askForSkillInvoke(objectName(), data)) {
				room->broadcastSkillInvoke(objectName());
				int to_throw = room->askForCardChosen(pangde, effect.to, "he", objectName(), false, Card::MethodDiscard);
				room->throwCard(Sanguosha->getCard(to_throw), effect.to, pangde);
			}
		}
		return false;
	}
};

//周宇昂-龙套
class Longtao: public TriggerSkill{
public:
	Longtao(): TriggerSkill("longtao"){
		events<<SlashMissed;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		SlashEffectStruct effect = data.value<SlashEffectStruct>();
		if(effect.from!= player || !player->askForSkillInvoke(objectName(),data)) return false;
		QString choice;
		if(!player->isWounded())
			choice = "draw";
		else
			choice = room->askForChoice(player,objectName(),"recover+draw",data);
		if(choice == "draw")
			player->drawCards(2);
		else{
			RecoverStruct re;
			re.who = player;
			room->recover(player,re);
		}
		return false;
	}
};

//游飞-友善
class Youshan: public TriggerSkill{
public:
	Youshan(): TriggerSkill("youshan"){
		events<<Damaged;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->isAlive() && !target->hasSkill(objectName());
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		ServerPlayer *youfei = room->findPlayerBySkillName(objectName());
		if(!youfei || !youfei->isAlive()) return false;
		DamageStruct damage = data.value<DamageStruct>();
		for(int i=0;i<damage.damage;i++){
			if(player->isKongcheng()) return false;
			if(!player->isWounded()) return false;
			if(!youfei->askForSkillInvoke(objectName(),data)) return false;
			if(!player->canDiscard(player,"h")||!player->isWounded()) return false;
			int card_id = room->askForCardChosen(youfei,player,"h",objectName());			
			room->showCard(player, card_id);
			const Card* card = Sanguosha->getCard(card_id);
			if (card->isRed()) {
				if (!player->isJilei(card))
					room->throwCard(card, player);
				room->broadcastSkillInvoke(objectName());
				RecoverStruct recover;
				recover.who = youfei;
				room->recover(player, recover);
			}
		}
		return false;
	}
};

//游飞-自愈
class Ziyu: public TriggerSkill{
public:
	Ziyu(): TriggerSkill("ziyu"){
		events<<Damaged;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(!player->isAlive() || !player->askForSkillInvoke(objectName(),data)) return false;
		DamageStruct damage = data.value<DamageStruct>();
		for(int i=0;i<damage.damage;i++){
			if(!player->isWounded()) return false;
			JudgeStruct judge;
			judge.pattern = ".|red";
			judge.reason = objectName();
			judge.who = player;
			judge.good = true;
			room->judge(judge);
			if(judge.isGood()){
				RecoverStruct re;
				re.who = player;
				room->recover(player,re);
			}
		}		
		return false;
	}
};

//朱徐开-老实
class Laoshi: public TriggerSkill{
public:
	Laoshi(): TriggerSkill("laoshi"){
		events<<CardEffected;
		frequency = Frequent;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
		CardEffectStruct effect = data.value<CardEffectStruct>();
		if (effect.to == effect.from)
			return false;
		if (effect.card->isNDTrick()) {			
			if (effect.to->hasSkill(objectName()) && effect.from) {
				LogMessage log;
				log.type = "#LaoshiGooD";
				log.from = effect.to;
				log.to << effect.from;
				log.arg = effect.card->objectName();
				log.arg2 = objectName();
				room->sendLog(log);
				room->notifySkillInvoked(effect.to, objectName());				
				return true;
			}
		}
		return false;
	}
};

//朱徐开-拾遗
class Shiyi: public TriggerSkill{
public:
	Shiyi(): TriggerSkill("shiyi"){
		events<<BeforeCardsMove;
		//frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *caozhi, QVariant &data) const{
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from == caozhi || move.from == NULL)
			return false;
		if (move.to_place == Player::DiscardPile
			&& ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD
			||move.reason.m_reason == CardMoveReason::S_REASON_JUDGEDONE)) {
				QList<int> card_ids;
				int i = 0;
				foreach (int card_id, move.card_ids) {
					if (Sanguosha->getCard(card_id)->getNumber() == 2*caozhi->getHp()
						&& ((move.reason.m_reason == CardMoveReason::S_REASON_JUDGEDONE
						&& move.from_places[i] == Player::PlaceJudge
						&& move.to_place == Player::DiscardPile)
						|| (move.reason.m_reason != CardMoveReason::S_REASON_JUDGEDONE
						&& room->getCardOwner(card_id) == move.from
						&& (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip))))
						card_ids << card_id;
					i++;
				}
				if (card_ids.empty())
					return false;
				else if (caozhi->askForSkillInvoke(objectName(), data)) {					
					while (!card_ids.empty()) {
						room->fillAG(card_ids, caozhi);
						int id = room->askForAG(caozhi, card_ids, true, objectName());
						if (id == -1) {
							room->clearAG(caozhi);
							break;
						}
						card_ids.removeOne(id);
						room->clearAG(caozhi);
					}
					if (!card_ids.empty()) {
						//room->broadcastSkillInvoke("shiyi");
						foreach (int id, card_ids) {
							if (move.card_ids.contains(id)) {
								move.from_places.removeAt(move.card_ids.indexOf(id));
								move.card_ids.removeOne(id);
								data = QVariant::fromValue(move);
							}
							room->moveCardTo(Sanguosha->getCard(id), caozhi, Player::PlaceHand, move.reason, true);
							if (!caozhi->isAlive())
								break;
						}
					}
				}
		}
		return false;
	}
};

//邵进涛-得意
class Deyi: public TriggerSkill {
public:
	Deyi(): TriggerSkill("deyi") {
		events << TargetConfirmed << CardEffected;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if (triggerEvent == TargetConfirmed) {
			CardUseStruct use = data.value<CardUseStruct>();
			if (use.to.length() <= 1 || !use.to.contains(player)
				|| !use.card->isKindOf("TrickCard")
				|| !room->askForSkillInvoke(player, objectName(), data))
				return false;
			player->tag["Deyi"] = use.card->toString();
			room->broadcastSkillInvoke(objectName());
			player->drawCards(1);
		} else {
			if (!player->isAlive() || !player->hasSkill(objectName()))
				return false;
			CardEffectStruct effect = data.value<CardEffectStruct>();
			if (player->tag["Deyi"].isNull() || player->tag["Deyi"].toString() != effect.card->toString())
				return false;
			player->tag["Deyi"] = QVariant(QString());
			LogMessage log;
			log.type = "#DeyiAvoid";
			log.from = player;
			log.arg = effect.card->objectName();
			log.arg2 = objectName();
			room->sendLog(log);
			return true;
		}
		return false;
	}
};

//张志宁-迟到
class Chidao: public TriggerSkill {
public:
	Chidao(): TriggerSkill("chidao") {
		events << Damaged;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const{
		if (player->getPhase() != Player::NotActive)
			return false;

		ServerPlayer *current = room->getCurrent();
		if (current && current->isAlive() && current->getPhase() != Player::NotActive) {
			//room->broadcastSkillInvoke(objectName(), 1);
			room->notifySkillInvoked(player, objectName());
			if (player->getMark("@chidao") == 0)
				room->addPlayerMark(player, "@chidao");

			LogMessage log;
			log.type = "#ChidaoDamaged";
			log.from = player;
			room->sendLog(log);
		}
		return false;
	}
};

class ChidaoProtect: public TriggerSkill {
public:
	ChidaoProtect(): TriggerSkill("#chidao-protect") {
		events << CardEffected;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
		CardEffectStruct effect = data.value<CardEffectStruct>();
		if ((effect.card->isKindOf("Slash") || effect.card->isNDTrick()) && effect.to->getMark("@chidao") > 0) {
			//room->broadcastSkillInvoke("chidao", 2);
			room->notifySkillInvoked(effect.to, "chidao");
			LogMessage log;
			log.type = "#ChidaoAvoid";
			log.from = effect.to;
			log.arg = "chidao";
			room->sendLog(log);

			return true;
		}
		return false;
	}
};

class ChidaoClear: public TriggerSkill {
public:
	ChidaoClear(): TriggerSkill("#chidao-clear") {
		events << EventPhaseChanging << Death;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if (triggerEvent == EventPhaseChanging) {
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if (change.to != Player::NotActive)
				return false;
		} else {
			DeathStruct death = data.value<DeathStruct>();
			if (death.who != player || player != room->getCurrent())
				return false;
		}

		foreach (ServerPlayer *p, room->getAllPlayers()) {
			if (p->getMark("@chidao") > 0)
				room->setPlayerMark(p, "@chidao", 0);
		}

		return false;
	}
};

//张志宁-胃口
class Weikou: public TriggerSkill {
public:
	Weikou(): TriggerSkill("weikou") {
		frequency = Frequent;
		events << CardUsed;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *yueying, QVariant &data) const{
		CardUseStruct use = data.value<CardUseStruct>();

		if (use.card->isNDTrick() && room->askForSkillInvoke(yueying, objectName())) {
			//room->broadcastSkillInvoke("weikou");
			yueying->drawCards(1);
		}

		return false;
	}
};

//陈文杰-耍赖
class Shualai: public MasochismSkill {
public:
	Shualai(): MasochismSkill("shualai") {
	}

	virtual void onDamaged(ServerPlayer *simayi, const DamageStruct &damage) const{
		ServerPlayer *from = damage.from;
		Room *room = simayi->getRoom();
		QVariant data = QVariant::fromValue(from);
		if (from && !from->isNude() && room->askForSkillInvoke(simayi, "shualai", data)) {
			room->broadcastSkillInvoke(objectName());
			int card_id = room->askForCardChosen(simayi, from, "he", "shualai");
			CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, simayi->objectName());
			room->obtainCard(simayi, Sanguosha->getCard(card_id),
				reason, room->getCardPlace(card_id) != Player::PlaceHand);
		}
	}
};

//江建军-文艺
class Wenyi: public OneCardViewAsSkill {
public:
	Wenyi(): OneCardViewAsSkill("wenyi") {
	}

	virtual bool viewFilter(const Card *to_select) const{
		const Card *card = to_select;

		switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
		case CardUseStruct::CARD_USE_REASON_PLAY: {
			return card->isKindOf("Jink");
												  }
		case CardUseStruct::CARD_USE_REASON_RESPONSE:
		case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
			QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
			if (pattern == "slash")
				return card->isKindOf("Jink");
			else if (pattern == "jink")
				return card->isKindOf("Slash");
														  }
		default:
			return false;
		}
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return Slash::IsAvailable(player);
	}

	virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
		return pattern == "jink" || pattern == "slash";
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		if (originalCard->isKindOf("Slash")) {
			Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
			jink->addSubcard(originalCard);
			jink->setSkillName(objectName());
			return jink;
		} else if (originalCard->isKindOf("Jink")) {
			Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
			slash->addSubcard(originalCard);
			slash->setSkillName(objectName());
			return slash;
		} else
			return NULL;
	}
};


//---------------行政部、前台、销售等-------------------
//陶佳琪-血崩
class Xuebeng: public TriggerSkill{
public:
	Xuebeng(): TriggerSkill("xuebeng"){
		events<<Damaged;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *taojiaqi, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		for(int i =0;i<damage.damage;i++){
			if(taojiaqi->askForSkillInvoke(objectName(),data)){
				foreach(ServerPlayer *p,room->getOtherPlayers(taojiaqi)){
					room->loseHp(p);
				}
			}
			continue;
		}
		return false;
	}
};

//陶佳琪-护岗
HugangCard::HugangCard() {	
	will_throw = true;
	m_skillName = "hugang";
	target_fixed = true;
}

void HugangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	room->loseHp(source);
	foreach(ServerPlayer *target,room->getOtherPlayers(source)){		
		RecoverStruct recover;
		recover.who = source;
		room->recover(target,recover);
	}
	if(source->isAlive()) source->drawCards(1);
}

class Hugang:public ZeroCardViewAsSkill{
public:
	Hugang(): ZeroCardViewAsSkill("hugang") {		
	}

	virtual bool isEnabledAtPlay(const Player *taojiaqi) const{
		return !taojiaqi->hasUsed("HugangCard");
	}

	virtual const Card *viewAs() const{
		return new HugangCard;
	}
};

//张笋-后勤
class Houqin: public TriggerSkill {
public:
	Houqin(): TriggerSkill("houqin") {
		events << CardsMoveOneTime;		
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->isAlive();
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from == player && move.from_places.contains(Player::PlaceHand) && move.is_last_handcard) {
			ServerPlayer *zhangsun = room->findPlayerBySkillName(objectName());
			if(!zhangsun || !player->isAlive()) return false;
			room->setTag("current",QVariant::fromValue(player));
			if (room->askForSkillInvoke(zhangsun, objectName(), data)) {
				room->broadcastSkillInvoke(objectName());
				player->drawCards(1);				
			}
			room->removeTag("current");
		}		
		return false;
	}
};

class HouqinForZeroMaxCards: public TriggerSkill {
public:
	HouqinForZeroMaxCards(): TriggerSkill("#houqin-for-zero-maxcards") {
		events << EventPhaseChanging;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->isAlive();
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		PhaseChangeStruct change = data.value<PhaseChangeStruct>();
		if (change.from == Player::Discard && player->hasFlag("HouqinZeroMaxCards")) {
			player->setFlags("-HouqinZeroMaxCards");
			ServerPlayer *zhangsun = room->findPlayerBySkillName("houqin");
			if(!zhangsun || !player->isAlive()) return false;
			room->setTag("current",QVariant::fromValue(player));
			if (player->isKongcheng() && room->askForSkillInvoke(zhangsun, "houqin",data)) {
				room->broadcastSkillInvoke("houqin");
				player->drawCards(1);
			}
			room->removeTag("current");
		}		
		return false;
	}
};

//张笋-踢球
class Tiqiu: public TargetModSkill{
public:
	Tiqiu(): TargetModSkill("tiqiu"){
	}

	virtual int getExtraTargetNum(const Player *from, const Card *) const{
		if (from->hasSkill(objectName()))
			return 1;
		else
			return 0;
	}
};

//邢星宇-镜像
class Jingxiang: public TriggerSkill{
public:
	Jingxiang(): TriggerSkill("jingxiang"){
		events<<DamageInflicted;
	}

	virtual bool trigger(TriggerEvent,Room *room,ServerPlayer* xingxinyu,QVariant &data) const{
		if(xingxinyu->getHandcardNum()==0) return false;
		DamageStruct damage = data.value<DamageStruct>();
		if(damage.from == NULL || damage.from == xingxinyu ||
			!damage.card->isKindOf("Slash")||!xingxinyu->canDiscard(xingxinyu,"h")) return false;
		if(xingxinyu->askForSkillInvoke(objectName(),data)){
			if(room->askForDiscard(xingxinyu,objectName(),1,1,false,false,"#jingxiang")){			
				DamageStruct da;
				da.from = xingxinyu;
				da.to = damage.from;
				room->damage(da);
				if(da.to->isAlive())
					da.to->drawCards(1);
				return true;
			}		
			return false;
		}
		return false;
	}
};

//邢星宇-留守
class Liushou: public TriggerSkill{
public:
	Liushou(): TriggerSkill("liushou"){
		events<<EventPhaseStart;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room* room,ServerPlayer *xingxinyu,QVariant &data) const{
		if(xingxinyu->getPhase()== Player::Finish && xingxinyu->askForSkillInvoke(objectName(),data))
			xingxinyu->drawCards(1);
		return false;
	}
};

//唐俊杰-中庸
class Zhongyong: public TriggerSkill {
public:
	Zhongyong(): TriggerSkill("zhongyong") {
		events << CardEffected;
		frequency = Compulsory;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
		CardEffectStruct effect = data.value<CardEffectStruct>();
		if (effect.to == effect.from)
			return false;
		if (effect.card->isNDTrick()) {
			if (effect.from && effect.from->hasSkill(objectName())) {
				LogMessage log;
				log.type = "#ZhongyongBaD";
				log.from = effect.from;
				log.to << effect.to;
				log.arg = effect.card->objectName();
				log.arg2 = objectName();
				room->sendLog(log);
				room->notifySkillInvoked(effect.from, objectName());
				room->broadcastSkillInvoke(objectName(), 1);
				return true;
			}
			if (effect.to->hasSkill(objectName()) && effect.from) {
				LogMessage log;
				log.type = "#ZhongyongGooD";
				log.from = effect.to;
				log.to << effect.from;
				log.arg = effect.card->objectName();
				log.arg2 = objectName();
				room->sendLog(log);
				room->notifySkillInvoked(effect.to, objectName());
				room->broadcastSkillInvoke(objectName(), qrand() % 2 + 2);
				return true;
			}
		}
		return false;
	}
};

//唐俊杰-得道
DedaoCard::DedaoCard(){
	m_skillName = "dedao";
	will_throw = true;
	target_fixed = false;
}

bool DedaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty();
}

void DedaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	ServerPlayer *target = targets.first();
	QString choice;
	if(!target->isWounded())
		choice = "draw";
	else
		choice = room->askForChoice(target,"dedao","recover+draw");
	if(choice == "draw")
		target->drawCards(2);
	else{
		RecoverStruct recover;
		recover.who = source;
		room->recover(target,recover);
	}
}

class Dedao: public ViewAsSkill{
public:
	Dedao(): ViewAsSkill("dedao"){
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		if(selected.isEmpty())
			return !Self->isJilei(to_select);
		if(selected.length() == 1)
			return !Self->isJilei(to_select) && to_select->getTypeId() == selected.first()->getTypeId();
		return false;
	}
	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.length()!=2)
			return NULL;

		DedaoCard *card = new DedaoCard;
		card->addSubcards(cards);
		card->setSkillName(objectName());
		return card;
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player, "he") && !player->hasUsed("DedaoCard");
	}	
};

//张佩-发钱 
class Faqian: public OneCardViewAsSkill{
public:
	Faqian(): OneCardViewAsSkill("faqian"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player,"he");
	}

	virtual bool viewFilter(const Card *card) const{
		return card->getSuit() == Card::Heart;
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		AmazingGrace* card = new AmazingGrace(originalCard->getSuit(), originalCard->getNumber());
		card->addSubcard(originalCard->getId());
		card->setSkillName(objectName());
		return card;
	}
};

//张佩-补贴
class Butie: public TriggerSkill{
public:
	Butie(): TriggerSkill("butie"){
		events<<Damaged;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->isAlive();
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if(!damage.to || !damage.to->isAlive()) return false;
		ServerPlayer *zhangpei = room->findPlayerBySkillName(objectName());		
		for(int i = 0;i<damage.damage;i++){
			if(!zhangpei || zhangpei->isDead() || !zhangpei->askForSkillInvoke(objectName(),data)) return false;
			if(damage.to->isAlive())
				damage.to->drawCards(2);
		}
		return false;
	}
};

//张海波-收缴
ShoujiaoCard::ShoujiaoCard() {
}

bool ShoujiaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	if (targets.length() >= 2 || to_select == Self)
		return false;

	return !to_select->isAllNude();
}

void ShoujiaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	QList<CardsMoveStruct> moves;
	CardsMoveStruct move1;
	move1.card_ids << room->askForCardChosen(source, targets[0], "hej", "shoujiao");
	move1.to = source;
	move1.to_place = Player::PlaceHand;
	moves.push_back(move1);
	if (targets.length() == 2) {
		CardsMoveStruct move2;
		move2.card_ids << room->askForCardChosen(source, targets[1], "hej", "shoujiao");
		move2.to = source;
		move2.to_place = Player::PlaceHand;
		moves.push_back(move2);
	}
	room->moveCards(moves, false);
}

class ShoujiaoViewAsSkill: public ZeroCardViewAsSkill{
public:
	ShoujiaoViewAsSkill(): ZeroCardViewAsSkill("shoujiao"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return false;
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		return pattern == "@@shoujiao";
	}

	virtual const Card* viewAs() const{
		return new ShoujiaoCard;
	}
};

class Shoujiao: public TriggerSkill{
public:
	Shoujiao(): TriggerSkill("shoujiao"){
		events<<CardsMoveOneTime;
		frequency = Frequent;
		view_as_skill = new ShoujiaoViewAsSkill;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		bool can_invoke = false;
		QList<ServerPlayer *> other_players = room->getOtherPlayers(player);
		foreach (ServerPlayer *p, other_players) {
			if (!p->isAllNude()) {
				can_invoke = true;
				break;
			}
		}
		CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
		if (move.from == player && move.from_places.contains(Player::PlaceHand) && move.is_last_handcard) {
			if(player->getPhase()== Player::Discard && move.reason.m_reason == CardMoveReason::S_REASON_RULEDISCARD){
				room->setPlayerFlag(player,"ZeroCardsInDiscardPhase");
				return false;
			}

			if (can_invoke && room->askForUseCard(player, "@@shoujiao", "@shoujiao-card")) {
				//room->broadcastSkillInvoke(objectName());				
				return true;
			}
		}
		return false;
	}
};

class ShoujiaoZeroCards: public TriggerSkill{
public:
	ShoujiaoZeroCards(): TriggerSkill("#shoujiao-zerocards"){
		events<<EventPhaseChanging;		
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		bool can_invoke = false;
		QList<ServerPlayer *> other_players = room->getOtherPlayers(player);
		foreach (ServerPlayer *p, other_players) {
			if (!p->isAllNude()) {
				can_invoke = true;
				break;
			}
		}
		PhaseChangeStruct change = data.value<PhaseChangeStruct>();
		if (change.from == Player::Discard && player->hasFlag("ZeroCardsInDiscardPhase")) {
			player->setFlags("-ZeroCardsInDiscardPhase");
			if (can_invoke && player->isKongcheng() && room->askForUseCard(player, "@@shoujiao", "@shoujiao-card")) {
				//room->broadcastSkillInvoke("lianying");				
				return true;
			}
		}
		return false;
	}
};

//王建永-加密
JiamiCard::JiamiCard() {
	mute = true;
	will_throw = false;
	handling_method = Card::MethodNone;
}

bool JiamiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select->getPile("mi").isEmpty() && to_select != Self;
}

void JiamiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	ServerPlayer *target = targets.first();
	target->tag["JiamiSouce" + QString::number(getEffectiveId())] = QVariant::fromValue((PlayerStar)source);
	//room->broadcastSkillInvoke("jiami", 1);
	target->addToPile("mi", this, false);
}

class JiamiViewAsSkill: public OneCardViewAsSkill {
public:
	JiamiViewAsSkill(): OneCardViewAsSkill("jiami") {
		filter_pattern = ".|.|.|hand";
		response_pattern = "@@jiami";
	}

	virtual const Card *viewAs(const Card *originalcard) const{
		Card *card = new JiamiCard;
		card->addSubcard(originalcard);
		return card;
	}
};

class Jiami: public TriggerSkill {
public:
	Jiami(): TriggerSkill("jiami") {
		events << EventPhaseStart;
		view_as_skill = new JiamiViewAsSkill;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target != NULL;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const{
		if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && !player->isKongcheng()) {
			room->askForUseCard(player, "@@jiami", "@jiami-remove", -1, Card::MethodNone);
		} else if (player->getPhase() == Player::RoundStart && player->getPile("mi").length() > 0) {
			QList<int> bifa_list = player->getPile("mi");

			while (!bifa_list.isEmpty()) {
				int card_id = bifa_list.last();
				ServerPlayer *chenlin = player->tag["JiamiSouce" + QString::number(card_id)].value<PlayerStar>();
				QList<int> ids;
				ids << card_id;

				LogMessage log;
				log.type = "$JiamiView";
				log.from = player;
				log.card_str = QString::number(card_id);
				log.arg = "mi";
				room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toJsonValue());

				room->fillAG(ids, player);
				const Card *cd = Sanguosha->getCard(card_id);
				QString pattern;
				if (cd->isKindOf("BasicCard"))
					pattern = "BasicCard";
				else if (cd->isKindOf("TrickCard"))
					pattern = "TrickCard";
				else if (cd->isKindOf("EquipCard"))
					pattern = "EquipCard";
				QVariant data_for_ai = QVariant::fromValue(pattern);
				pattern.append("|.|.|hand");
				const Card *to_give = NULL;
				if (!player->isKongcheng() && chenlin && chenlin->isAlive())
					to_give = room->askForCard(player, pattern, "@jiami-give", data_for_ai, Card::MethodNone, chenlin);
				if (chenlin && to_give) {
					//room->broadcastSkillInvoke(objectName(), 2);
					chenlin->obtainCard(to_give, false);
					player->obtainCard(cd, false);
				} else {
					//room->broadcastSkillInvoke(objectName(), 2);
					CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), objectName(), QString());
					room->throwCard(cd, reason, NULL);
					room->loseHp(player);
				}
				bifa_list.removeOne(card_id);
				room->clearAG(player);
				player->tag.remove("JiamiSouce" + QString::number(card_id));
			}
		}
		return false;
	}
};

//路丽霞-许可
class Xuke: public TriggerSkill {
public:
	Xuke(): TriggerSkill("xuke") {
		events << CardUsed;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target->getPhase() == Player::Play;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		CardUseStruct use = data.value<CardUseStruct>();
		if (use.card->isKindOf("Slash")) {
			ServerPlayer *guanping = room->findPlayerBySkillName(objectName());
			if (guanping && guanping->canDiscard(guanping, "he")
				&& room->askForCard(guanping, "..", "@xuke", data, objectName())) {
					//room->broadcastSkillInvoke(objectName(), use.card->isRed() ? 2 : 1);
					if (use.m_addHistory)
						room->addPlayerHistory(player, use.card->getClassName(), -1);
					if (use.card->isRed())
						guanping->drawCards(1);
			}
		}
		return false;
	}
};

//李建伟-接送
JiesongCard::JiesongCard() {
	mute = true;
}

bool JiesongCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select->getMark("jiesong" + Self->objectName()) == 0 && to_select->getHandcardNum() != to_select->getHp();
}

void JiesongCard::onEffect(const CardEffectStruct &effect) const{
	int handcard_num = effect.to->getHandcardNum();
	int hp = effect.to->getHp();
	
	Room *room = effect.from->getRoom();
	room->addPlayerMark(effect.to, "jiesong" + effect.from->objectName());
	if (handcard_num > hp) {
		//room->broadcastSkillInvoke("songci", 2);
		effect.to->gainMark("@song");
		room->askForDiscard(effect.to, "songci", 2, 2, false, true);
	} else if (handcard_num < hp) {
		//room->broadcastSkillInvoke("songci", 1);
		effect.to->gainMark("@jie");
		effect.to->drawCards(2, "jiesong");
	}
}

class JiesongViewAsSkill: public ZeroCardViewAsSkill {
public:
	JiesongViewAsSkill(): ZeroCardViewAsSkill("jiesong") {
	}

	virtual const Card *viewAs() const{
		return new JiesongCard;
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		if (player->getMark("jiesong" + player->objectName()) == 0 && player->getHandcardNum() != player->getHp()) return true;
		foreach (const Player *sib, player->getAliveSiblings())
			if (sib->getMark("jiesong" + player->objectName()) == 0 && sib->getHandcardNum() != sib->getHp())
				return true;
		return false;
	}
};

class Jiesong: public TriggerSkill {
public:
	Jiesong(): TriggerSkill("jiesong") {
		events << Death;
		view_as_skill = new JiesongViewAsSkill;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target && target->hasSkill(objectName());
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		DeathStruct death = data.value<DeathStruct>();
		if (death.who != player) return false;
		foreach (ServerPlayer *p, room->getAllPlayers()) {
			if (p->getMark("@jie") > 0)
				room->setPlayerMark(p, "@jie", 0);
			if (p->getMark("@song") > 0)
				room->setPlayerMark(p, "@song", 0);
			if (p->getMark("jiesong" + player->objectName()) > 0)
				room->setPlayerMark(p, "jiesong" + player->objectName(), 0);
		}
		return false;
	}
};

//吴凡-制图
class Zhitu: public ViewAsSkill {
public:
	Zhitu(): ViewAsSkill("zhitu") {
	}	

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		return selected.isEmpty();
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if(cards.length()!=1) return false;
		int c = Self->property("card").toInt();	
		if (c>0) {			
			Card *card = Sanguosha->cloneCard(Sanguosha->getCard(c)->objectName());
			card->setSkillName(objectName());
			card->addSubcards(cards);
			return card;
		} else
			return NULL;
	}

	virtual bool isEnabledAtPlay(const Player *player) const{		
		int c = player->property("card").toInt();
		if(c<=0) return false;
		if (player->isKongcheng())
			return false;
		else
			return player->getMark("used") == 0;
	}
};

class ZhituClear: public TriggerSkill{
public:
	ZhituClear(): TriggerSkill("#zhitu"){
		events<<EventPhaseStart<<CardUsed<<CardsMoveOneTime<<EventPhaseChanging<<Death<<EventLoseSkill;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(triggerEvent == EventPhaseStart){
			if(player->getPhase()!= Player::Play) return false;
			room->setPlayerProperty(player,"card",-1);
		}else if(triggerEvent == CardUsed){
			CardUseStruct u = data.value<CardUseStruct>();
			if(player->getPhase() !=Player::Play || u.from!=player || !u.card ||!u.card->isNDTrick() 
				|| u.card->isKindOf("Nullification")) return false;
			if(Sanguosha->getCard(u.card->getEffectiveId())->objectName() != u.card->objectName()){
				if(player->getMark("used") == 0)
					room->setPlayerMark(player,"used",1);
				return false;
			}
			//const char *card;
			room->setPlayerProperty(player,"card",u.card->getEffectiveId());		
		}else if(triggerEvent == CardsMoveOneTime){
			if(player->getPhase()!=Player::Play) return false;
			CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
			if(move.from==player && move.from_places.contains(Player::PlaceHand) && move.to_place == Player::DiscardPile &&
				move.reason.m_reason ==  CardMoveReason::S_REASON_RECAST){
					int id = move.card_ids.first();
					if(Sanguosha->getCard(id)->objectName() != "iron_chain"){
						if(player->getMark("used") == 0)
							room->setPlayerMark(player,"used",1);
						return false;
					}			
			}
		}else if(triggerEvent == EventPhaseChanging){
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if(change.from!=Player::Play) return false;			
			if(player->getMark("used")>0)
				room->setPlayerMark(player,"used",0);				
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who!=player) return false;			
			if(player->getMark("used")>0)
				room->setPlayerMark(player,"used",0);			
		}else if(triggerEvent == EventLoseSkill && data.toString() == "zhitu"){			
			if(player->getMark("used")>0)
				room->setPlayerMark(player,"used",0);				
		}
		return false;
	}
};

//吴凡-修图
class Xiutu: public TriggerSkill{
public:
	Xiutu(): TriggerSkill("xiutu"){
		events<<Damaged;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		if(damage.to != player || player->isKongcheng() || !player->canDiscard(player,"h") ||
			!player->isAlive() || !player->askForSkillInvoke(objectName(),data)) return false;
		if(room->askForDiscard(player,objectName(),1,1,false,false,"#xiutu")){
			RecoverStruct recover;
			recover.who = player;
			room->recover(player,recover);
		}
		return false;
	}
};

//李广民-仁义
RenyiCard::RenyiCard() {
	target_fixed = true;
}

void RenyiCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const{
	if (player->isKongcheng()) return;
	ServerPlayer *who = room->getCurrentDyingPlayer();
	if (!who) return;

	player->turnOver();
	CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName());
	reason.m_playerId = who->objectName();
	room->obtainCard(who, player->wholeHandCards(), reason, false);

	RecoverStruct recover;
	recover.who = player;
	room->recover(who, recover);
}

class Renyi: public ZeroCardViewAsSkill {
public:
	Renyi(): ZeroCardViewAsSkill("renyi") {
	}

	virtual bool isEnabledAtPlay(const Player *) const{
		return false;
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		return pattern == "peach" && !player->isKongcheng();
	}

	virtual const Card *viewAs() const{
		return new RenyiCard;
	}
};

//李广民-大笑
class Daxiao: public TriggerSkill{
public:
	Daxiao(): TriggerSkill("daxiao"){
		events<<Damaged;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(player->faceUp()) return false;
		if(!player->askForSkillInvoke(objectName(),data)) return false;
		player->turnOver();
		if(player->isAlive())
			player->drawCards(1,objectName());
		return false;
	}
};

//张峥-和气 
class Heqi: public TriggerSkill{
public:
	Heqi(): TriggerSkill("heqi"){
		events<<DamageInflicted<<DamageCaused;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(triggerEvent == DamageInflicted){
			DamageStruct damage = data.value<DamageStruct>();
			if(!damage.from || damage.from == player || player->isKongcheng()) return false;
			if(!room->askForSkillInvoke(player,objectName(),data)) return false;
			if(room->askForDiscard(player,objectName(),1,1,false,false,"#heqi")){
				LogMessage log;
				log.type = "#HeqiDefend";
				log.from = damage.from;
				log.to<<player;
				log.arg = QString::number(damage.damage);
				room->sendLog(log);
				return true;
			}							
		}else if(triggerEvent == DamageCaused){
			DamageStruct damage = data.value<DamageStruct>();
			if(!damage.to->isAlive() || damage.to == player || !player->askForSkillInvoke(objectName(),data)) return false;
			player->drawCards(1,objectName());
			LogMessage log;
			log.type = "#HeqiDefend";
			log.from = player;
			log.to<<damage.to;
			log.arg = QString::number(damage.damage);
			room->sendLog(log);
			return true;
		}
		return false;
	}
};

//李明升-雷厉
class Leili: public TriggerSkill {
public:
	Leili(): TriggerSkill("leili") {
		events << TargetConfirmed;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		CardUseStruct use = data.value<CardUseStruct>();
		if (player != use.from || !use.card->isKindOf("Slash"))
			return false;
		QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
		int index = 0;
		foreach (ServerPlayer *p, use.to) {
			if (player->askForSkillInvoke(objectName(), QVariant::fromValue(p))) {
				//room->broadcastSkillInvoke(objectName());

				//p->setFlags("LeiliTarget"); // For AI

				JudgeStruct judge;
				judge.pattern = ".|red";
				judge.good = true;
				judge.reason = objectName();
				judge.who = player;
				room->judge(judge);
				/*try {
					room->judge(judge);
				}
				catch (TriggerEvent triggerEvent) {
					if (triggerEvent == TurnBroken || triggerEvent == StageChange)
						p->setFlags("-LeiliTarget");
					throw triggerEvent;
				}*/

				if (judge.isGood()) {
					LogMessage log;
					log.type = "#NoJink";
					log.from = p;
					room->sendLog(log);
					jink_list.replace(index, QVariant(0));
				}

				//p->setFlags("-LeiliTarget");
			}
			index++;
		}
		player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
		return false;
	}
}; 

//李明升-忽悠
HuyouCard::HuyouCard(){
	target_fixed = true;
	will_throw = false;
}

void HuyouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	source->addToPile("huyou",this,false);
	foreach(ServerPlayer *p,room->getOtherPlayers(source)){
		Card::Suit suit1 = room->askForSuit(p,"huyou");
		QString suit = Card::Suit2String(suit1);
		LogMessage log;
		log.type = "#ChooseSuit";
		log.from = p;
		log.arg = suit;
		room->sendLog(log);
		p->gainMark("@"+suit);
	}
	int id = source->getPile("huyou").first();
	Card *card = Sanguosha->getCard(id);
	QString suit2 = Card::Suit2String(card->getSuit());
	room->getThread()->delay(1500);
	source->removePileByName("huyou");
	foreach(ServerPlayer *p,room->getOtherPlayers(source)){
		if(p->getMark("@"+suit2)==0)
			room->loseHp(p,1);
		else{
			if(p->isAlive())
				p->drawCards(1);
		}
	}
	foreach(ServerPlayer *p,room->getOtherPlayers(source,true)){
		if(!p->isAlive())
			p->throwAllMarks();
		if(p->getMark("@spade")>0)
			room->setPlayerMark(p,"@spade",0);
		else if(p->getMark("@heart")>0)
			room->setPlayerMark(p,"@heart",0);
		else if(p->getMark("@club")>0)
			room->setPlayerMark(p,"@club",0);
		else if(p->getMark("@diamond")>0)
			room->setPlayerMark(p,"@diamond",0);
	}
}

class Huyou: public OneCardViewAsSkill{
public:
	Huyou(): OneCardViewAsSkill("huyou"){
		filter_pattern = ".|.|.|hand!";
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return !player->hasUsed("HuyouCard") && !player->isKongcheng() && player->canDiscard(player,"h");
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		HuyouCard *card = new HuyouCard;
		card->addSubcard(originalCard);
		card->setSkillName(objectName());
		return card;
	}
};

//熊熠-奔走 
BenzouCard::BenzouCard() {
}

bool BenzouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	if (!targets.isEmpty() || to_select == Self)
		return false;

	int rangefix = 0;
	if (!subcards.isEmpty() && Self->getWeapon() && Self->getWeapon()->getId() == subcards.first()) {
		const Weapon *card = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
		rangefix += card->getRange() - 1;
	}

	return Self->distanceTo(to_select, rangefix) <= Self->getAttackRange();
}

void BenzouCard::onEffect(const CardEffectStruct &effect) const{
	Room *room = effect.to->getRoom();

	if (subcards.isEmpty())
		room->loseHp(effect.from);

	room->damage(DamageStruct("benzou", effect.from, effect.to));
}

class Benzou: public ViewAsSkill {
public:
	Benzou(): ViewAsSkill("benzou") {
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return !player->hasUsed("BenzouCard");
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		return selected.isEmpty() && to_select->isKindOf("Weapon") && !Self->isJilei(to_select);
	}

	virtual const Card *viewAs(const QList<const Card *> &cards) const{
		if (cards.isEmpty())
			return new BenzouCard;
		else if (cards.length() == 1) {
			BenzouCard *card = new BenzouCard;
			card->addSubcards(cards);

			return card;
		} else
			return NULL;
	}

	virtual int getEffectIndex(const ServerPlayer *, const Card *card) const{
		return 2 - card->subcardsLength();
	}
};

//--------------------------老总们----------------------

//陈立平-远见
class Yuanjian: public TriggerSkill{
public:
	Yuanjian(): TriggerSkill("yuanjian"){
		events<<EventPhaseStart;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent,Room *room, ServerPlayer *chenliping, QVariant &data) const{
		if(chenliping->getPhase()!=Player::Finish) return false;
		if(chenliping->askForSkillInvoke(objectName(),data)){
			QList<int>cards = room->getNCards(2);
			room->fillAG(cards);
			room->getThread()->delay(2000);
			foreach(int c,cards){
				Card *card = Sanguosha->getCard(c);
				if(card->isRed()){
					cards.removeOne(c);
					chenliping->addToPile("zhan",card->getId());
				}else if(card->isBlack()){
					cards.removeOne(c);
					chenliping->obtainCard(card);
				}
			}
			room->clearAG();
		}
		return false;
	}

};

class YuanjianSkip: public TriggerSkill{
public:
	YuanjianSkip():TriggerSkill("#yuanjianskip"){
		events<<EventPhaseEnd;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && !target->hasSkill(objectName());
	}

	virtual bool trigger(TriggerEvent,Room *room,ServerPlayer *player, QVariant &data) const{
		if(player->getPhase()!= Player::Start) return false;
		ServerPlayer *chenliping = room->findPlayerBySkillName(objectName());
		if(!chenliping || chenliping->getPile("zhan").isEmpty()) return false;
		room->setTag("current",QVariant::fromValue(player));
		if(!chenliping->askForSkillInvoke(objectName(),data)){
			room->removeTag("current");
			return false;
		}
		QList<int> cards = chenliping->getPile("zhan");
		room->fillAG(cards, chenliping);
		int card_id = room->askForAG(chenliping, cards, false, objectName());
		room->clearAG();
		if (card_id != -1) {
			CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), objectName(), QString());
			room->throwCard(Sanguosha->getCard(card_id), reason, NULL);
			player->skip(Player::Play);
		}
		room->removeTag("current");
		return false;
	}
};

class YuanjianClear: public TriggerSkill{
public:
	YuanjianClear(): TriggerSkill("#yuanjian-clear"){
		events<<EventLoseSkill<<Death;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(triggerEvent == EventLoseSkill && data.toString() == "yuanjian"){
			if(!player->getPile("zhan").isEmpty())
				player->removePileByName("zhan");
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == player && !player->getPile("zhan").isEmpty())
				player->removePileByName("zhan");
		}
		return false;
	}
};

//陈立平-乐施
class Leshi: public TriggerSkill{
public:
	Leshi(): TriggerSkill("leshi"){
		events<<EventPhaseEnd;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent,Room *room,ServerPlayer* chenliping,QVariant &data) const{
		if(chenliping->getPhase()!= Player::Discard) return false;
		if(chenliping->getPile("zhan").isEmpty()) return false;
		int n = chenliping->getPile("zhan").length();
		chenliping->removePileByName("zhan");
		room->notifySkillInvoked(chenliping, objectName());
		LogMessage log;
		log.type = "#leshi";
		log.from = chenliping;
		log.arg = objectName();
		room->sendLog(log);
		foreach(ServerPlayer *p,room->getAllPlayers()){
			p->drawCards(n);
		}
		return false;
	}
};

//陈立平--老板
LaobanCard::LaobanCard() {
	target_fixed = true;
	mute = true;
}

void LaobanCard::onUse(Room *room, const CardUseStruct &card_use) const{
	ServerPlayer *yuanshu = card_use.from;

	QStringList choices;
	if (yuanshu->hasLordSkill("jijiang") && room->getLord()->hasLordSkill("jijiang") && Slash::IsAvailable(yuanshu))
		choices << "jijiang";

	/*if (yuanshu->hasLordSkill("weidai") && Analeptic::IsAvailable(yuanshu) && !yuanshu->hasFlag("drank"))
		choices << "weidai";*/

	if (choices.isEmpty())
		return;

	QString choice = room->askForChoice(yuanshu, "laoban", choices.join("+"));

	if (choice == "jijiang") {
		QList<ServerPlayer *> targets;
		foreach (ServerPlayer* target, room->getOtherPlayers(yuanshu)){
			if (yuanshu->canSlash(target))
				targets << target;
		}

		ServerPlayer* target = room->askForPlayerChosen(yuanshu, targets, "jijiang");
		if(target){
			JijiangCard *jijiang = new JijiangCard;
			jijiang->setSkillName("laoban");
			CardUseStruct use;
			use.card = jijiang;
			use.from = yuanshu;
			use.to << target;
			room->useCard(use);
		}
	} /*else {
		WeidaiCard *weidai = new WeidaiCard;
		weidai->setSkillName("laoban");
		CardUseStruct use;
		use.card = weidai;
		use.from = yuanshu;
		room->useCard(use);
	}*/
}

class LaobanViewAsSkill: public ZeroCardViewAsSkill {
public:
	LaobanViewAsSkill(): ZeroCardViewAsSkill("laoban") {
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return (player->hasLordSkill("jijiang") && Slash::IsAvailable(player));
			/*||(player->hasLordSkill("weidai") && Analeptic::IsAvailable(player) && !player->hasFlag("drank"));*/
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		/*if (player->hasLordSkill("weidai"))
			return pattern == "peach+analeptic";
		else */if (player->hasLordSkill("jijiang")) {
			JijiangViewAsSkill *jijiang = new JijiangViewAsSkill;
			jijiang->deleteLater();
			return jijiang->isEnabledAtResponse(player, pattern);
		}

		return false;
	}

	virtual const Card *viewAs() const{
		/*if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
		return new WeidaiCard;
		else*/
			return new LaobanCard;
	}
};

class Laoban: public GameStartSkill {
public:
	Laoban(): GameStartSkill("laoban") {
		frequency = Compulsory;
		view_as_skill = new LaobanViewAsSkill;
	}

	virtual void onGameStart(ServerPlayer *player) const{
		/*Room *room = player->getRoom();
		ServerPlayer *lord = room->getLord();
		if(lord->hasLordSkill())
		player->addSkill(lord->lord)*/
		return;
	}
};

//赵建军--加薪
JiaxinCard::JiaxinCard(){
	will_throw = true;
	target_fixed = false;
	m_skillName = "jiaxin";
}

bool JiaxinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return targets.isEmpty() && to_select!=Self;
}

void JiaxinCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	ServerPlayer *target = targets.first();
	room->addPlayerMark(target,"@jiaxin");
	LogMessage log;
	log.type = "#jiaxinlog";
	log.from = source;
	log.to<<target;
	room->sendLog(log);
}

class Jiaxin: public OneCardViewAsSkill{
public:
	Jiaxin(): OneCardViewAsSkill("jiaxin"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return !player->hasUsed("JiaxinCard") && player->canDiscard(player,"h");
	}

	virtual bool viewFilter(const Card *to_select) const{
		return !to_select->isEquipped();
	}

	virtual const Card *viewAs(const Card *originalCard) const{
		JiaxinCard *card = new JiaxinCard;
		card->setSkillName(objectName());
		card->addSubcard(originalCard);
		return card;
	}
};

//加薪-额外摸牌
class JiaxinExtraCard: public DrawCardsSkill{
public:
	JiaxinExtraCard(): DrawCardsSkill("#jiaxin_extracard"){
		frequency = Compulsory;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->getMark("@jiaxin")>0;
	}

	virtual int getDrawNum(ServerPlayer *player, int n) const{
		if(player->getMark("@jiaxin")>0){
			Room *room = player->getRoom();
			room->notifySkillInvoked(player, "jiaxin");
			return n+player->getMark("@jiaxin");
		}else
			return n;
	}
};

//加薪-增加手牌上限
class JiaxinMaxCards: public MaxCardsSkill{
public:
	JiaxinMaxCards(): MaxCardsSkill("#jiaxin_maxcards"){
	}

	virtual int getExtra(const Player *target) const{
		if(target->getMark("@jiaxin")>0)
			return target->getMark("@jiaxin");
		else
			return 0;
	}
};

//加薪-去除标记
class JiaxinClear: public TriggerSkill{
public:
	JiaxinClear(): TriggerSkill("#jiaxin_clear"){
		events<<EventPhaseChanging<<Death;
		frequency = Compulsory;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target && target->getMark("@jiaxin")>0;
	}

	virtual bool trigger(TriggerEvent triggerEvent,Room* room,ServerPlayer* player,QVariant& data) const{
		if(player->getMark("@jiaxin")==0) return false;
		if(triggerEvent == EventPhaseChanging){
			PhaseChangeStruct change = data.value<PhaseChangeStruct>();
			if(change.to == Player::NotActive)
				player->loseMark("@jiaxin",player->getMark("@jiaxin"));
		}else if(triggerEvent == Death){
			DeathStruct death = data.value<DeathStruct>();
			if(death.who == player)
				player->loseMark("@jiaxin",player->getMark("@jiaxin"));
		}
		return false;
	}
};

//赵建军-出差
class Chuchai: public TriggerSkill{
public:
	Chuchai(): TriggerSkill("chuchai"){
		events<<DamageForseen;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		bool can_invoke = true;
		foreach(ServerPlayer* p,room->getOtherPlayers(player)){
			if(p->getHp() < player->getHp()){
				can_invoke = false;
				break;
			}
		}
		if(!can_invoke) return false;
		DamageStruct damage = data.value<DamageStruct>();
		if (damage.nature != DamageStruct::Fire) {
			LogMessage log;
			log.type = "#ChuchaiProtect";
			log.from = player;
			log.arg = QString::number(damage.damage);
			if (damage.nature == DamageStruct::Normal)
				log.arg2 = "normal_nature";
			else if (damage.nature == DamageStruct::Thunder)
				log.arg2 = "thunder_nature";
			room->sendLog(log);
			room->notifySkillInvoked(player, objectName());
			return true;
		} else
			return false;
	}
};

//周凡利-绩效
JixiaoCard::JixiaoCard(){
	will_throw = true;
	target_fixed = true;
	m_skillName = "jixiao";
}

void JixiaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	foreach(ServerPlayer* target,room->getOtherPlayers(source)){
		//room->attachSkillToPlayer(target,"#jixiaoask");
		const Card *card = room->askForUseCard(target,"@@jixiaoask","#jixiaoask",-1,Card::MethodResponse);
		//room->detachSkillFromPlayer(target,"#jixiaoask");
		if(card!=NULL){			
			QString choice;
			if(!target->isWounded())
				choice = "draw";
			else
				choice = room->askForChoice(target,"jixiaogood","draw+recover");
			if(choice == "draw")
				target->drawCards(2);
			else{
				RecoverStruct re;
				re.who = source;
				room->recover(target,re);
			}
		}else{
			QString choice;
			if(!target->canDiscard(target,"he") || target->getCardCount(true)<2) 
				choice = "damage";
			else
				choice = room->askForChoice(target,"jixiaobad","discard1+damage");
			if(choice == "discard1")
				room->askForDiscard(target,"jixiao",2,2,false,true,"#jixiao_discard");
			else{
				DamageStruct da;
				da.from = source;
				da.to = target;
				room->damage(da);
			}
		}		
	}
	
}

class Jixiao: public ViewAsSkill{
public:
	Jixiao(): ViewAsSkill("jixiao"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return player->canDiscard(player,"he") && !player->hasUsed("JixiaoCard");
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		if(selected.isEmpty())
			return true;
		else if(selected.length() == 1)
			return to_select->getTypeId() == selected.first()->getTypeId();
		return false;
	}

	virtual const Card* viewAs(const QList<const Card *> &cards) const{
		if(cards.length()!=2) return NULL;
		JixiaoCard *card = new JixiaoCard;
		card->setSkillName(objectName());
		card->addSubcards(cards);
		return card;
	}
};

//绩效弃牌要求
class JixiaoAsk: public ViewAsSkill{
public:
	JixiaoAsk(): ViewAsSkill("jixiaoask"){
	}

	virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
		return pattern == "@@jixiaoask";
	}

	virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
		if(selected.isEmpty())
			return to_select->isKindOf("Jink") || to_select->isKindOf("Slash");
		else if(selected.length()==1){
			if(selected.first()->isKindOf("Slash"))
				return to_select->isKindOf("Jink");
			else
				return to_select->isKindOf("Slash");
		}
		return false;
	}

	virtual const Card* viewAs(const QList<const Card *> &cards) const{
		if(cards.length()!=2) return NULL;
		DummyCard *card = new DummyCard;
		card->setSkillName("jixiao");
		card->addSubcards(cards);
		return card;
	}
};

//丁建完-求解
class Qiujie: public TriggerSkill{
public:
	Qiujie(): TriggerSkill("qiujie"){
		events<<EventPhaseStart;
		frequency = Frequent;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		if(player->getPhase() != Player::Finish || !player->askForSkillInvoke(objectName(),data)) return false;
		QList<int> cards = room->getNCards(3), left;
		LogMessage log;
		log.type = "$ViewDrawPile";
		log.from = player;
		log.card_str = IntList2StringList(cards).join("+");
		room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toJsonValue());
		left = cards;
		QList<int> hearts, non_hearts;
		foreach (int card_id, cards) {
			const Card *card = Sanguosha->getCard(card_id);
			if (card->getSuit() == Card::Heart)
				hearts << card_id;
			else
				non_hearts << card_id;
		}
		DummyCard *dummy = new DummyCard;
		if (!hearts.isEmpty()) {
			do {
				room->fillAG(left, player, non_hearts);
				int card_id = room->askForAG(player, hearts, true, objectName());
				if (card_id == -1) {
					room->clearAG(player);
					break;
				}
				hearts.removeOne(card_id);
				left.removeOne(card_id);
				dummy->addSubcard(card_id);
				room->clearAG(player);
			} while (!hearts.isEmpty());
			if (dummy->subcardsLength() > 0) {
				room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, Json::Value(room->getDrawPile().length() + dummy->subcardsLength()));
				player->obtainCard(dummy);
				foreach (int id, dummy->getSubcards())
					room->showCard(player, id);
			}
			dummy->deleteLater();
		}
		if (!left.isEmpty())
			room->askForGuanxing(player, left, true);	
		return false;
	}
};

//丁建完-指导
class Zhidao: public PhaseChangeSkill {
public:
	Zhidao(): PhaseChangeSkill("zhidao") {	
		frequency = Frequent;
	}

	virtual bool onPhaseChange(ServerPlayer *target) const{
		if (target->getPhase() != Player::Start)
			return false;
		if(!target->askForSkillInvoke(objectName())) return false;
		Room *room = target->getRoom();
		ServerPlayer *to = room->askForPlayerChosen(target, room->getAlivePlayers(), objectName(), "zhidao-invoke", true, true);
		if (to) {
			//room->broadcastSkillInvoke(objectName());
			QList<int> ids = room->getNCards(1, false);
			const Card *card = Sanguosha->getCard(ids.first());
			room->obtainCard(to, card, false);
			if (!to->isAlive())
				return false;
			room->showCard(to, ids.first());

			if (card->isKindOf("EquipCard")) {
				if (to->isWounded()) {
					RecoverStruct recover;
					recover.who = target;
					room->recover(to, recover);
				}
				if (to->isAlive() && !to->isCardLimited(card, Card::MethodUse))
					room->useCard(CardUseStruct(card, to, to));
			}
		}
		return false;
	}
};

//龚雄-文档 
WendangCard::WendangCard(){
	will_throw = true;
	target_fixed = false;
	m_skillName = "wendang";
}

bool WendangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	return to_select!=Self && !to_select->isKongcheng() &&to_select->canDiscard(to_select,"h");
}

void WendangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
	Card::Suit suit1 = room->askForSuit(source,"wendang");
	QString suit = Card::Suit2String(suit1);
	LogMessage log;
	log.type = "#ChooseSuit";
	log.from = source;
	log.arg = suit;
	room->sendLog(log);
	source->gainMark("@"+suit);
	ServerPlayer* target = targets.first();
	room->setTag("suit",QVariant::fromValue(suit));
	if(!target->isKongcheng() && target->canDiscard(target,"h")){
		/*int id = room->askForCardChosen(target,target,"h","wendang",true,Card::MethodDiscard);*/
		const Card *c = room->askForExchange(target, "wendang", 1,false,"#wendang",false);
		const Card *realcard = Sanguosha->getCard(c->getEffectiveId());
		if(realcard){
			room->throwCard(realcard,target,target);
			if(realcard->getSuitString()!=suit){
				if(target->isAlive()){
					target->drawCards(1);
					target->turnOver();
				}
			}
		}		
	}
	room->removeTag("suit");
	if (source->getMark("@"+suit)>0)
		source->loseAllMarks("@"+suit);
}

class Wendang: public ZeroCardViewAsSkill{
public:
	Wendang(): ZeroCardViewAsSkill("wendang"){
	}

	virtual bool isEnabledAtPlay(const Player *player) const{
		return !player->hasUsed("WendangCard");
	}

	virtual const Card *viewAs() const{
		return new WendangCard;
	}
};

//海波-神秘
class Shenmi: public TriggerSkill{
public:
	Shenmi(): TriggerSkill("shenmi"){
		events<<TurnStart;
		frequency = Compulsory;
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		QStringList old_skills = room->getTag("old_skill").toString().split("+");
		foreach(QString skill,old_skills){			
			if(player->hasSkill(skill))
				room->detachSkillFromPlayer(player,skill,false,true);							
		}
		room->removeTag("old_skill");
		QSet<QString> ban;
		foreach (ServerPlayer *player, room->getAlivePlayers()) {
			QString name = player->getGeneralName();
			if (Sanguosha->isGeneralHidden(name)) {
				QString fname = Sanguosha->findConvertFrom(name);
				if (!fname.isEmpty()) name = fname;
			}
			ban << name;

			if (!player->getGeneral2()) continue;

			name = player->getGeneral2Name();
			if (Sanguosha->isGeneralHidden(name)) {
				QString fname = Sanguosha->findConvertFrom(name);
				if (!fname.isEmpty()) name = fname;
			}
			ban << name;
		}
		QString generalname = Sanguosha->getRandomGenerals(1,ban).first();
		const General *general = Sanguosha->getGeneral(generalname);

		foreach (ServerPlayer *p, room->getAllPlayers()) {
			room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, player->objectName(), generalname, QList<ServerPlayer *>() << p);
		}

		LogMessage log2;
		log2.type = "#GetShenmiDetail";
		log2.from = player;
		log2.arg = generalname;
		//room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log2.toJsonValue());
		room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_SKILL, log2.toJsonValue());


		QString kingdom = general->getKingdom();
		if (player->getKingdom() != kingdom) {
			if (kingdom == "god") {
				kingdom = room->askForKingdom(player);

				LogMessage log;
				log.type = "#ChooseKingdom";
				log.from = player;
				log.arg = kingdom;
				room->sendLog(log);
			}
			room->setPlayerProperty(player, "kingdom", kingdom);
		}

		if (player->getGender() != general->getGender())
			player->setGender(general->getGender());
		//界面显示
		/*Json::Value arg(Json::arrayValue);
		arg[0] = (int)QSanProtocol::S_GAME_EVENT_SHENMI;
		arg[1] = QSanProtocol::Utils::toJsonString(player->objectName());
		arg[2] = QSanProtocol::Utils::toJsonString(general->objectName());
		arg[3] = QSanProtocol::Utils::toJsonString(generalname);
		room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);*/

		
		QStringList new_skills;
		foreach(const Skill* skill,general->getVisibleSkillList()){
			if (skill->isLordSkill()|| skill->getFrequency() == Skill::Wake)
				continue;
			if(!player->hasSkill(skill->objectName())){
				room->acquireSkill(player,skill->objectName(),true);
				new_skills<<skill->objectName();
			}			
		}
		room->setTag("old_skill",QVariant::fromValue(new_skills.join("+")));
		return false;
	}
};

class ShenmiClear: public DetachEffectSkill {
public:
	ShenmiClear(): DetachEffectSkill("#shenmi") {
	}

	virtual void onSkillDetached(Room *room, ServerPlayer *player) const{
		if (player->getKingdom() != player->getGeneral()->getKingdom() && player->getGeneral()->getKingdom() != "god")
			room->setPlayerProperty(player, "kingdom", player->getGeneral()->getKingdom());
		if (player->getGender() != player->getGeneral()->getGender())
			player->setGender(player->getGeneral()->getGender());
		foreach(QString skill,room->getTag("old_skill").toString().split("+")){
			if(player->hasSkill(skill))
				room->detachSkillFromPlayer(player, skill, false, true);
		}
		room->removeTag("old_skill");		
	}
};

//危文琼-组织
class Zuzhi: public TriggerSkill {
public:
	Zuzhi(): TriggerSkill("zuzhi") {
		events << TargetConfirming;
	}

	virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		CardUseStruct use = data.value<CardUseStruct>();
		if (use.card->isKindOf("Slash")) {
			QList<ServerPlayer *> targets;
			foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
				if (!p->isKongcheng() && p != use.from)
					targets << p;
			}
			if (targets.isEmpty()) return false;
			ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "zuzhi-invoke", true, true);
			if (target) {				
				const Card *card = NULL;
				if (target->getHandcardNum() > 1) {
					card = room->askForCard(target, ".!", "@zuzhi-give:" + player->objectName(), data, Card::MethodNone);
					if (!card)
						card = target->getHandcards().at(qrand() % target->getHandcardNum());
				} else {
					Q_ASSERT(target->getHandcardNum() == 1);
					card = target->getHandcards().first();
				}
				player->obtainCard(card);
				room->showCard(player, card->getEffectiveId());
				if (!card->isKindOf("Jink")) {
					if (use.from->canSlash(target, use.card, false)) {
						use.to.append(target);
						room->sortByActionOrder(use.to);
						data = QVariant::fromValue(use);
					}
				}
			}
		}
		return false;
	}
};


//扩展包，创建武将、赋予技能等；
TongyuanPackage::TongyuanPackage()
    : Package("tongyuan")
{
	//--------------建模组----------------------
    General *zhangzuobao = new General(this, "zhangzuobao", "mo",3); // 张作宝
    zhangzuobao->addSkill(new Tonggan);
	zhangzuobao->addSkill(new Gongku);

	General *zhengmin = new General(this,"zhengmin","mo",3);//郑敏
	zhengmin->addSkill(new Datui);
	zhengmin->addSkill(new Hebi);

	General *huanglei = new General(this,"huanglei","mo");//黄磊
	huanglei->addSkill(new Zican);

	General *chenlu = new General(this,"chenlu$","mo");//陈路
	chenlu->addSkill(new BenxiWeapon);
	chenlu->addSkill(new BenxiArmor);
	chenlu->addSkill(new Fuchi);
	related_skills.insertMulti("benxi","#benxi-armor");

	General *zhangfan = new General(this,"zhangfan","mo",3,false);//张凡
	zhangfan->addSkill(new Nvhan);
	zhangfan->addSkill(new Mengmei);
	
	General *quyan = new General(this,"quyan","mo",3);//屈严
	quyan->addSkill(new Quanquan);
	quyan->addSkill(new QuanquanTargetMod);
	quyan->addSkill(new QuanquanClear);
	quyan->addSkill(new Xiaopang);
	related_skills.insertMulti("quanquan","#quanquan-target");
	related_skills.insertMulti("quanquan","#quanquan-clear");

	General *shangguanduansen = new General(this,"shangguanduansen","mo",3);//上官端森
	shangguanduansen->addSkill(new Houji);
	shangguanduansen->addSkill(new Bofa);

	General *luruikun = new General(this,"luruikun","mo",3);//陆瑞琨
	luruikun->addSkill(new Kouwei);
	luruikun->addSkill("huijia");

	General *baobingrui = new General(this,"baobingrui","mo");//鲍丙瑞
	baobingrui->addSkill(new Datou);

	General *zhanghaiming = new General(this,"zhanghaiming","mo");//张海明
	zhanghaiming->addSkill(new Feiyu);

	General *zhaoyan = new General(this,"zhaoyan","mo",3);//赵岩
	zhaoyan->addSkill(new Huijia);
	zhaoyan->addSkill(new Biye);

	General *xiegang = new General(this,"xiegang$","mo");//谢刚
	xiegang->addSkill(new Jianmo);
	xiegang->addSkill(new JianmoMaxCard);
	xiegang->addSkill(new Youhua);
	xiegang->addSkill(new Yonghu);
	related_skills.insertMulti("jianmo","jianmo-card");

	General *xuxuehai = new General(this,"xuxuehai","mo");//徐学海
	xuxuehai->addSkill(new Qibo);

	General *dingji = new General(this,"dingji","mo");//丁吉
	dingji->addSkill(new Yeya);
	dingji->addSkill(new Qianjin);

	General *zhufeng = new General(this,"zhufeng","mo");//朱锋
	zhufeng->addSkill(new Peixun);

	General *chenchang = new General(this,"chenchang","mo");//陈昌
	chenchang->addSkill(new Yuanzhu);

	General *heshan = new General(this,"heshan","mo",3,false);//何姗
	heshan->addSkill(new Cheli);
	heshan->addSkill("huijia");

	General *mazhongfan = new General(this,"mazhongfan","mo",3);//马中帆
	mazhongfan->addSkill(new Wocao);
	mazhongfan->addSkill(new Nima);

	//-------------------行政、销售、前台等---------------------
	General *taojiaqi = new General(this,"taojiaqi","qun",3,false);//陶佳琪
	taojiaqi->addSkill(new Xuebeng);
	taojiaqi->addSkill(new Hugang);

	General *zhangsun = new General(this,"zhangsun","qun",3);//张笋
	zhangsun->addSkill(new Houqin);
	zhangsun->addSkill(new HouqinForZeroMaxCards);
	zhangsun->addSkill(new Tiqiu);
	related_skills.insertMulti("houqin","#houqin-for-zero-maxcards");

	General *xingxinyu = new General(this,"xingxinyu","qun",3,false);//邢鑫宇
	xingxinyu->addSkill(new Jingxiang);
	xingxinyu->addSkill(new Liushou);

	General *tangjunjie = new General(this,"tangjunjie","qun",3);//唐俊杰
	tangjunjie->addSkill(new Zhongyong);
	tangjunjie->addSkill(new Dedao);

	General *zhangpei = new General(this,"zhangpei","qun",3,false);//张佩
	zhangpei->addSkill(new Faqian);
	zhangpei->addSkill(new Butie);

	General *zhanghaibo = new General(this,"zhanghaibo","qun",4,false);//张海波
	zhanghaibo->addSkill(new Shoujiao);
	zhanghaibo->addSkill(new ShoujiaoZeroCards);
	related_skills.insertMulti("shoujiao","#shoujiao-zerocards");

	General *wangjianyong = new General(this,"wangjianyong","qun");//王建永
	wangjianyong->addSkill(new Jiami);

	General *lulixia = new General(this,"lulixia","qun",4,false);//路丽霞
	lulixia->addSkill(new Xuke);

	General *lijianwei = new General(this,"lijianwei","qun",3);//李建伟
	lijianwei->addSkill(new Jiesong);
	lijianwei->addSkill("feiche");

	General *wufan = new General(this,"wufan","qun",3,false);//吴凡
	wufan->addSkill(new Zhitu);
	wufan->addSkill(new ZhituClear);
	wufan->addSkill(new Xiutu);
	related_skills.insertMulti("zhitu","#zhitu");

	General *liguangmin = new General(this,"liguangmin","qun",3);//李广民
	liguangmin->addSkill(new Renyi);
	liguangmin->addSkill(new Daxiao);

	General *zhangzheng = new General(this,"zhangzheng","qun",4);//张峥
	zhangzheng->addSkill(new Heqi);

	General *limingsheng = new General(this,"limingsheng","qun",3);//李明升
	limingsheng->addSkill(new Leili);
	limingsheng->addSkill(new Huyou);

	General *huanghao = new General(this,"huanghao","qun",3);//黄昊
	huanghao->addSkill("huyou");
	huanghao->addSkill("feiche");

	General *xiongyi = new General(this,"xiongyi","qun");//熊熠
	xiongyi->addSkill(new Benzou);


	//--------------------武汉研发部、嵌入式组--------------------
	General *liuqi = new General(this,"liuqi$","yan",4);//刘奇
	liuqi->addSkill(new Suanfa);
	liuqi->addSkill(new Kaolao);

	General *zhangxincheng = new General(this,"zhangxincheng","yan",3);//张新城
	zhangxincheng->addSkill(new Bianma);
	zhangxincheng->addSkill(new BianmaDefend);
	zhangxincheng->addSkill(new Tiaoshi);
	related_skills.insertMulti("bianma","bianma-defend");

	General *luoxueqin = new General(this,"luoxueqin","yan",3,false);//骆雪芹
	luoxueqin->addSkill(new Shuishen);
	luoxueqin->addSkill(new Shishang);

	General *houwenjie = new General(this,"houwenjie","yan",3,false);//侯文洁
	houwenjie->addSkill(new Houge);
	houwenjie->addSkill(new Xinkuan);

	General *fangxiaojian = new General(this,"fangxiaojian","yan",3);//方孝健
	fangxiaojian->addSkill(new Suihe);
	fangxiaojian->addSkill(new JizhiFang);

	General *xiongtao = new General(this,"xiongtao","yan",3);//熊焘
	xiongtao->addSkill(new Dashen);
	xiongtao->addSkill(new Qiangzhuang);

	General *liucongwen = new General(this,"liucongwen","yan",3);//刘从文
	liucongwen->addSkill(new Xiaozi);
	liucongwen->addSkill(new Fendou);
	liucongwen->addSkill(new Congwen);
	liucongwen->addSkill(new CongwenDefend);
	related_skills.insertMulti("congwen","#congwen_defend");

	General *hexiangliang = new General(this,"hexiangliang","yan");//何相良
	hexiangliang->addSkill(new Yushen);

	General *zhangxiaolong = new General(this,"zhangxiaolong","yan",3);//张晓龙
	zhangxiaolong->addSkill(new Jiushen);
	zhangxiaolong->addSkill(new Biaoyan);

	General *yaoyunzhi = new General(this,"yaoyunzhi","ping");//姚云志
	yaoyunzhi->addSkill(new Qianxu);

	General *zhanghongchang = new General(this,"zhanghongchang$","yan",3);//张洪昌
	zhanghongchang->addSkill(new Shoucang);
	zhanghongchang->addSkill(new Quanjiu);
	zhanghongchang->addSkill(new Xuanjiang);
	zhanghongchang->addSkill(new XuanjiangDraw);
	related_skills.insertMulti("xuanjiang","#xuanjiang");

	General *wangxianglin = new General(this,"wangxianglin","mo",3,false);//王湘淋
	wangxianglin->addSkill(new Aixiao);
	wangxianglin->addSkill(new Chuyi);

	General *yanghao = new General(this,"yanghao","yan",3);//杨浩
	yanghao->addSkill(new Youxi);
	yanghao->addSkill(new Youyong);

	General *tianxianzhao = new General(this,"tianxianzhao","yan",3);//田显钊
	tianxianzhao->addSkill(new Yinren);
	tianxianzhao->addSkill(new Weihu);


	//--------------------二楼平台组----------------------------
	General *luwei = new General(this,"luwei","ping",3);//陆伟
	luwei->addSkill(new Tuhao);
	luwei->addSkill(new Feiche);

	General *zhaozuqian = new General(this,"zhaozuqian","ping",3);//赵祖乾
	zhaozuqian->addSkill(new Jiangyou);
	zhaozuqian->addSkill(new Yingdi);
	zhaozuqian->addSkill(new Dese);

	General *guoruimin = new General(this,"guoruimin","ping",3,false);//郭瑞敏
	guoruimin->addSkill(new Nvzong);
	guoruimin->addSkill(new Dajie);

	General *hanlu = new General(this,"hanlu","ping",3,false);//韩璐
	hanlu->addSkill(new Dabao);
	hanlu->addSkill(new DabaoDistance);
	hanlu->addSkill(new DabaoClear);
	hanlu->addSkill(new Fabu);
	related_skills.insertMulti("dabao","#dabao-distance");
	related_skills.insertMulti("dabao","#dabao-clear");

	General *zhanghehua = new General(this,"zhanghehua$","ping",3);//张和华
	zhanghehua->addSkill(new Yanfa);
	zhanghehua->addSkill(new Jicuo);
	zhanghehua->addSkill(new Shouji);

	General *guojunfeng = new General(this,"guojunfeng$","ping",3);//郭俊峰
	guojunfeng->addSkill(new Jiucuo);
	guojunfeng->addSkill(new Chandao);
	guojunfeng->addSkill(new Bangfu);

	General *zhoulei = new General(this,"zhoulei","ping",3);//周磊
	zhoulei->addSkill(new Ceshi);
	zhoulei->addSkill("feiche");

	General *wangling = new General(this,"wangling","ping",3,false);//汪玲
	wangling->addSkill(new Chihuo);
	wangling->addSkill(new Buan);

	General *zhouyuang = new General(this,"zhouyuang","ping");//周宇昂
	zhouyuang->addSkill(new Longtao);

	General *youfei = new General(this,"youfei","ping",3);//游飞
	youfei->addSkill(new Youshan);
	youfei->addSkill(new Ziyu);

	General *zhuxukai = new General(this,"zhuxukai","ping",3);//朱徐开
	zhuxukai->addSkill(new Laoshi);
	zhuxukai->addSkill(new Shiyi);

	General *shaojintao = new General(this,"shaojintao","ping");//邵进涛
	shaojintao->addSkill(new Deyi);

	General *zhangzhining = new General(this,"zhangzhining","ping",3);//张志宁
	zhangzhining->addSkill(new Chidao);
	zhangzhining->addSkill(new ChidaoProtect);
	zhangzhining->addSkill(new ChidaoClear);
	zhangzhining->addSkill(new Weikou);
	related_skills.insertMulti("chidao","#chidao-protect");
	related_skills.insertMulti("chidao","#chidao-clear");

	General *chenwenjie = new General(this,"chenwenjie","ping");//陈文杰
	chenwenjie->addSkill(new Shualai);

	General *jiangjianjun = new General(this,"jiangjianjun","ping");//江建军
	jiangjianjun->addSkill(new Wenyi);

	//-------------------老总们-------------------------------
	General *chenliping = new General(this,"chenliping","god",3);//陈立平
	chenliping->addSkill(new Yuanjian);
	chenliping->addSkill(new YuanjianSkip);
	chenliping->addSkill(new YuanjianClear);
	chenliping->addSkill(new Leshi);
	//chenliping->addSkill("weidi");
	chenliping->addSkill(new Laoban);
	related_skills.insertMulti("yuanjian","#yuanjianskip");
	related_skills.insertMulti("yuanjian","#yuanjian-clear");

	General *zhaojianjun = new General(this,"zhaojianjun","god",3);//赵建军
	zhaojianjun->addSkill(new Jiaxin);
	zhaojianjun->addSkill(new JiaxinClear);
	zhaojianjun->addSkill(new JiaxinExtraCard);
	zhaojianjun->addSkill(new JiaxinMaxCards);
	zhaojianjun->addSkill(new Chuchai);
	zhaojianjun->addSkill("laoban");
	related_skills.insertMulti("jiaxin","jiaxin_extracard");
	related_skills.insertMulti("jiaxin","jiaxin_clear");
	related_skills.insertMulti("jiaxin","jiaxin_maxcards");

	General *zhoufanli = new General(this,"zhoufanli","god");//周凡利
	zhoufanli->addSkill(new Jixiao);
	zhoufanli->addSkill("laoban");

	General *dingjianwan = new General(this,"dingjianwan","god",3);//丁建完
	dingjianwan->addSkill(new Qiujie);
	dingjianwan->addSkill(new Zhidao);
	dingjianwan->addSkill("laoban");

	General *gongxiong = new General(this,"gongxiong","god");//龚雄
	gongxiong->addSkill(new Wendang);
	gongxiong->addSkill("laoban");

	General *haibo = new General(this,"haibo","god",4);//海波
	haibo->addSkill(new Shenmi);
	haibo->addSkill(new ShenmiClear);
	haibo->addSkill("laoban");
	related_skills.insertMulti("shenmi","#shenmi");

	General *weiwenqiong = new General(this,"weiwenqiong","god",4,false);//危文琼
	weiwenqiong->addSkill(new Zuzhi);
	weiwenqiong->addSkill("laoban");


	addMetaObject<TongganCard>();
	addMetaObject<GongkuCard>();
	addMetaObject<FuchiCard>();
	addMetaObject<QuanquanCard>();
	addMetaObject<XiaopangCard>();
	addMetaObject<HugangCard>();
	addMetaObject<TuhaoCard>();
	addMetaObject<NvzongCard>();
	addMetaObject<LaobanCard>();
	addMetaObject<QiboCard>();
	addMetaObject<YuanzhuCard>();
	addMetaObject<FabuCard>();
	addMetaObject<DedaoCard>();
	addMetaObject<DashenCard>();
	addMetaObject<JiaxinCard>();
	addMetaObject<JixiaoCard>();
	addMetaObject<ShoujiCard>();
	addMetaObject<BiaoyanCard>();
	addMetaObject<QianxuCard>();
	addMetaObject<XuanjiangCard>();
	addMetaObject<ChuyiCard>();
	//addMetaObject<YouxiCard>();
	addMetaObject<WendangCard>();
	addMetaObject<ShoujiaoCard>();
	addMetaObject<JiamiCard>();
	addMetaObject<JiesongCard>();
	addMetaObject<RenyiCard>();
	addMetaObject<HuyouCard>();
	addMetaObject<BenzouCard>();

	skills << new FuchiViewAsSkill<<new Fangzhen<<new JixiaoAsk<<new ShoujiViewAsSkill
		<<new BangfuAsk;
}

ADD_PACKAGE(Tongyuan)