#ifndef _TONGYUANDREAM_H
#define _TONGYUANDREAM_H

#include "standard.h"

class Dream: public SingleTargetTrick {
	Q_OBJECT

public:
	Q_INVOKABLE Dream(Card::Suit suit, int number);
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class WorkSign:public AOE {
	Q_OBJECT

public:
	Q_INVOKABLE WorkSign(Card::Suit suit, int number);
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class LeaderAttention: public SingleTargetTrick {
	Q_OBJECT

public:
	Q_INVOKABLE LeaderAttention(Card::Suit suit, int number);

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class FinalPrize: public GlobalEffect {
	Q_OBJECT

public:
	Q_INVOKABLE FinalPrize(Card::Suit suit = Heart, int number = 1);
	virtual bool isCancelable(const CardEffectStruct &effect) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class Dios: public Disaster {
	Q_OBJECT

public:
	Q_INVOKABLE Dios(Card::Suit suit, int number);

	virtual void takeEffect(ServerPlayer *target) const;
};

class HelpSign: public SingleTargetTrick {
	Q_OBJECT

public:
	Q_INVOKABLE HelpSign(Card::Suit suit, int number);
	//void setCancelable(bool cancelable) const;
	//virtual void setCancelable(bool cancelable){cancelable = true};
	//virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
	virtual bool isAvailable(const Player *player) const;
	virtual QString getCommonEffectName() const;
//private:
//	TriggerSkill *dismissdamage;
};

class TongyuanDreamPackage: public Package {
	Q_OBJECT

public:
	TongyuanDreamPackage();
};

#endif