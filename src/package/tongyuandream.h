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

class TongyuanDreamPackage: public Package {
	Q_OBJECT

public:
	TongyuanDreamPackage();
};

#endif