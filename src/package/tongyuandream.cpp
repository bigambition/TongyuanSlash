#include "tongyuandream.h"
#include "client.h"
#include "engine.h"
#include "general.h"
#include "room.h"

//同元梦
Dream::Dream(Suit suit, int number)
	: SingleTargetTrick(suit, number)
{
	setObjectName("dream");
}

bool Dream::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
	return targets.length() < total_num && to_select != Self;
}

void Dream::onEffect(const CardEffectStruct &effect) const{
	if(effect.from->isAlive())
		effect.from->drawCards(2);
	if(effect.to->isAlive())
		effect.to->drawCards(2);
}

//上班打卡
WorkSign::WorkSign(Suit suit, int number)
	: AOE(suit, number)
{
	setObjectName("worksign");
}

void WorkSign::onEffect(const CardEffectStruct &effect) const{
	Room *room = effect.to->getRoom();
	const Card *slash = room->askForCard(effect.to,
		"TrickCard",
		"worksign-trick:"+ effect.from->objectName(),
		QVariant::fromValue(effect),
		Card::MethodResponse,
		effect.from->isAlive() ? effect.from : NULL);
	if (!slash) {
		//if (slash->getSkillName() == "spear") room->setEmotion(effect.to, "weapon/spear");
		//room->setEmotion(effect.to, "killer");
	//} else{
		room->damage(DamageStruct(this, effect.from->isAlive() ? effect.from : NULL, effect.to));
		room->getThread()->delay();
	}
}

//领导重视
LeaderAttention::LeaderAttention(Suit suit, int number)
	: SingleTargetTrick(suit, number)
{
	setObjectName("leaderattention");
}

bool LeaderAttention::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
	return targets.length() < total_num && to_select != Self;
}

void LeaderAttention::onEffect(const CardEffectStruct &effect) const{
	RecoverStruct recover;
	recover.who = effect.from;
	Room *room = effect.from->getRoom();
	room->recover(effect.to,recover);
	if(effect.to->isAlive())
		effect.to->drawCards(1);
}

//项目奖
FinalPrize::FinalPrize(Suit suit, int number)
	: GlobalEffect(suit, number)
{
	setObjectName("finalprize");
}

bool FinalPrize::isCancelable(const CardEffectStruct &effect) const{
	return TrickCard::isCancelable(effect);
}

void FinalPrize::onEffect(const CardEffectStruct &effect) const{
	//Room *room = effect.to->getRoom();
	if (!effect.to->isAlive())
		;//room->setEmotion(effect.to, "skill_nullify");
	else {
		effect.to->drawCards(1);
	}
}

//屌丝
Dios::Dios(Suit suit, int number):Disaster(suit, number) {
	setObjectName("dios");

	judge.pattern = ".|heart|2~9";
	judge.good = false;
	judge.reason = objectName();
}

void Dios::takeEffect(ServerPlayer *target) const{
	if(!target->getEquips().isEmpty())
		target->throwAllEquips();
	else
		target->getRoom()->damage(DamageStruct(this, NULL, target, 1, DamageStruct::Normal));
}

class DismissDamage: public TriggerSkill{
public:
	DismissDamage(): TriggerSkill("#dismissdamage"){
		events<< DamageInflicted;
		global = true;
	}

	virtual bool triggerable(const ServerPlayer *target) const{
		return target!=NULL && target->isAlive();
	}

	virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
		DamageStruct damage = data.value<DamageStruct>();
		//QString pattern = new  ExpPattern("Peach");
		foreach(ServerPlayer* p,room->getAllPlayers()){
			const Card* card1 = room->askForCard(p,"helpsign","@helpsign:"+damage.to->objectName(),data,
				Card::MethodNone,NULL,false,QString(),false);
			Card* card2 = const_cast<Card*>(card1);
			TrickCard* card = qobject_cast<TrickCard*>(card2);
			if(card){
				card->setCancelable(false);
				room->useCard(CardUseStruct(card,p,damage.to));
				if(p->getGender() == General::Male)
					room->broadcastSkillInvoke("helpsign",1);
				else if(p->getGender() == General::Female)
					room->broadcastSkillInvoke("helpsign",2);
				if(damage.to->hasSkills("noswuyan|luakaoshen|zhongyong|laoshi")&&p!=damage.to) continue;
				if(p->hasSkills("noswuyan|zhongyong") && p!=damage.to) continue;
				LogMessage log;
				log.type = "#dismissdamage";
				log.from = p;
				log.to<<damage.to;
				room->sendLog(log);
				return true;
			}
		}
		return false;
	}
};


//代人签到
HelpSign::HelpSign(Suit suit, int number)
	: SingleTargetTrick(suit, number)
{
	target_fixed = true;
	//cancelable = false;
	setObjectName("helpsign");	
	//cancelable = false;
	/*dismissdamage = new DismissDamage;
	dismissdamage->setParent(this);*/
}

//void HelpSign::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
//	// does nothing, just throw it
//	CardMoveReason reason(CardMoveReason::S_REASON_USE, source->objectName());
//	room->moveCardTo(this, source, NULL, Player::DiscardPile, reason);
//	//room->getThread()->addTriggerSkill(dismissdamage);		
//}


bool HelpSign::isAvailable(const Player *) const{
	return false;
}

QString HelpSign::getCommonEffectName() const{
	return "helpsign";
}

TongyuanDreamPackage::TongyuanDreamPackage()
	: Package("tongyuandream", Package::CardPack)
{
	QList<Card *> cards;

	// spade
	cards << new Dios(Card::Spade, 1)
	//	<< new Vine(Card::Spade, 2)
	//	<< new Analeptic(Card::Spade, 3)
	//	<< new ThunderSlash(Card::Spade, 4)
	//	<< new ThunderSlash(Card::Spade, 5)
	//	<< new ThunderSlash(Card::Spade, 6)
		<< new WorkSign(Card::Spade, 7)
	//	<< new ThunderSlash(Card::Spade, 8)
		<< new WorkSign(Card::Spade, 9)
	//	<< new SupplyShortage(Card::Spade, 10)
	//	<< new IronChain(Card::Spade, 11)
	//	<< new IronChain(Card::Spade, 12)
		<< new HelpSign(Card::Spade, 13);
	//// club
	cards << new Dios(Card::Club, 1)
	//	<< new Vine(Card::Club, 2)
	//	<< new Analeptic(Card::Club, 3)
	//	<< new SupplyShortage(Card::Club, 4)
	//	<< new ThunderSlash(Card::Club, 5)
	//	<< new ThunderSlash(Card::Club, 6)
		<< new WorkSign(Card::Club, 7)
		<< new HelpSign(Card::Club, 8);
	//	<< new Analeptic(Card::Club, 9)
	//	<< new IronChain(Card::Club, 10)
	//	<< new IronChain(Card::Club, 11)
	//	<< new IronChain(Card::Club, 12)
	//	<< new IronChain(Card::Club, 13);

	//// heart
	cards //<< new Dream(Card::Heart, 1);
	//	<< new FireAttack(Card::Heart, 2)
	//	<< new FireAttack(Card::Heart, 3)
	//	<< new FireSlash(Card::Heart, 4)
	//	<< new Peach(Card::Heart, 5)
		<< new LeaderAttention(Card::Heart, 6)
		<< new LeaderAttention(Card::Heart, 7)
		<< new LeaderAttention(Card::Heart, 8)
		<< new Dream(Card::Heart, 9)
		<< new Dream(Card::Heart, 10)
		<< new Dream(Card::Heart, 11)
	//	<< new Jink(Card::Heart, 12)
		<< new HelpSign(Card::Heart, 13);

	//// diamond
	cards << new FinalPrize(Card::Diamond, 1)
		<< new FinalPrize(Card::Diamond, 2)
		<< new FinalPrize(Card::Diamond, 3)
	//	<< new FireSlash(Card::Diamond, 4)
	//	<< new FireSlash(Card::Diamond, 5)
	//	<< new Jink(Card::Diamond, 6)
	//	<< new Jink(Card::Diamond, 7)
	//	<< new Jink(Card::Diamond, 8)
	//	<< new Analeptic(Card::Diamond, 9)
	//	<< new Jink(Card::Diamond, 10)
	//	<< new Jink(Card::Diamond, 11)
		<< new Dios(Card::Diamond, 12);

	//DefensiveHorse *hualiu = new DefensiveHorse(Card::Diamond, 13);
	//hualiu->setObjectName("HuaLiu");

	/*cards << hualiu;*/

	foreach (Card *card, cards)
		card->setParent(this);

	/*skills << new GudingBladeSkill << new FanSkill
		<< new VineSkill << new SilverLionSkill;*/
	skills<< new DismissDamage;
}

ADD_PACKAGE(TongyuanDream)
