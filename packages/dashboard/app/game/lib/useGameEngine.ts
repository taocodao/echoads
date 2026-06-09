'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import {
  PREDICTIONS, AD_CATALOG, GAME_EVENTS, CHAT_MESSAGES, GAME_META,
  type Prediction, type AdCreative, type GameEvent, type ChatMessage,
} from './gameData';

export type FeedEntry = {
  id: string;
  type: 'game' | 'ad' | 'prediction' | 'chat' | 'pod';
  text: string;
  emoji: string;
  timestamp: string;
  detail?: string;
};

export type BingoCell = { label: string; marked: boolean; free: boolean };

export function useGameEngine() {
  const clockRef = useRef(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const [elapsed, setElapsed] = useState(0);

  // Scoreboard
  const [homeScore, setHomeScore] = useState(GAME_META.homeScore);
  const [awayScore, setAwayScore] = useState(GAME_META.awayScore);
  const [quarter, setQuarter] = useState(GAME_META.quarter);
  const [clock, setClock] = useState(GAME_META.clock);

  // Active game state
  const [activePrediction, setActivePrediction] = useState<Prediction | null>(null);
  const [predictionTimer, setPredictionTimer] = useState(0);
  const [userPick, setUserPick] = useState<number | null>(null);
  const [predictionResolved, setPredictionResolved] = useState(false);
  const [points, setPoints] = useState(1250);
  const [flyPoints, setFlyPoints] = useState<string | null>(null);

  const [activeAd, setActiveAd] = useState<AdCreative | null>(null);
  const [lastAd, setLastAd] = useState<AdCreative | null>(null);
  const [adTimer, setAdTimer] = useState(0);

  const [feed, setFeed] = useState<FeedEntry[]>([]);
  const [chat, setChat] = useState<ChatMessage[]>([]);

  const [bingoBoard, setBingoBoard] = useState<BingoCell[]>(() =>
    ['Touchdown', 'Field Goal', 'Interception', 'Sack', 'Penalty Flag',
      'First Down', 'Timeout Called', 'Challenge Flag', '2-Point Conv.', 'False Start',
      'Fumble', 'Big Hit', 'FREE', 'Long Pass', 'No Gain',
      'Touchdown', '3rd Down Conv.', 'Punt', 'QB Scramble', 'Red Zone',
      'Holding Call', 'Incomplete Pass', 'Safety', '4th Down', 'Pick-6',
    ].map((label, i) => ({ label, marked: i === 12, free: i === 12 }))
  );
  const [bingoLines, setBingoLines] = useState(0);

  const firedEvents = useRef(new Set<string>());

  const addFeed = useCallback((entry: Omit<FeedEntry, 'id' | 'timestamp'>) => {
    setFeed(prev => [{
      ...entry,
      id: Math.random().toString(36).slice(2),
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
    }, ...prev].slice(0, 40));
  }, []);

  const awardPoints = useCallback((pts: number, label: string) => {
    setPoints(p => p + pts);
    setFlyPoints(`+${pts} pts`);
    setTimeout(() => setFlyPoints(null), 1500);
    addFeed({ type: 'prediction', text: label, emoji: '🎯', detail: `+${pts} pts earned` });
  }, [addFeed]);

  const markBingoCell = useCallback((label: string) => {
    setBingoBoard(prev => {
      const next = prev.map(c =>
        c.label === label && !c.marked && !c.free ? { ...c, marked: true } : c
      );
      // Count lines
      const lines = [
        [0,1,2,3,4],[5,6,7,8,9],[10,11,12,13,14],[15,16,17,18,19],[20,21,22,23,24],
        [0,5,10,15,20],[1,6,11,16,21],[2,7,12,17,22],[3,8,13,18,23],[4,9,14,19,24],
        [0,6,12,18,24],[4,8,12,16,20],
      ];
      const completed = lines.filter(l => l.every(i => next[i].marked || next[i].free)).length;
      setBingoLines(completed);
      return next;
    });
  }, []);

  // Clock tick
  useEffect(() => {
    timerRef.current = setInterval(() => {
      clockRef.current += 1;
      const t = clockRef.current;
      setElapsed(t);

      // Loop at 78s
      if (t > 78) { clockRef.current = 0; return; }

      // Update simulated game clock (counts down from 8:44 in Q3)
      const totalSecs = 8 * 60 + 44 - t;
      if (totalSecs > 0) {
        const m = Math.floor(totalSecs / 60);
        const s = totalSecs % 60;
        setClock(`${m}:${s.toString().padStart(2, '0')}`);
      }

      // Ad timer countdown
      setAdTimer(prev => {
        if (prev <= 1) { setActiveAd(null); return 0; }
        return prev - 1;
      });

      // Prediction timer countdown
      setPredictionTimer(prev => {
        if (prev <= 1 && activePrediction && userPick === null) {
          // Auto-lock — prediction missed
          setActivePrediction(null);
          return 0;
        }
        return prev > 0 ? prev - 1 : 0;
      });

      // Fire scripted events
      GAME_EVENTS.forEach(evt => {
        const key = `event-${evt.at}`;
        if (t === evt.at && !firedEvents.current.has(key)) {
          firedEvents.current.add(key);
          // Update score
          if (evt.scoreDelta) {
            setHomeScore(s => s + evt.scoreDelta!.home);
            setAwayScore(s => s + evt.scoreDelta!.away);
          }
          // Mark bingo cell
          if (evt.bingoCell) markBingoCell(evt.bingoCell);
          // Add to feed
          const emoji = {
            touchdown: '🏈', fieldgoal: '🥅', interception: '🙌',
            sack: '💥', penalty: '🚩', firstdown: '📍', timeout: '⏸️',
          }[evt.type] ?? '🏟️';
          addFeed({ type: 'game', text: evt.description, emoji });
        }
      });

      // Fire predictions
      PREDICTIONS.forEach(pred => {
        const key = `pred-${pred.id}`;
        if (t === pred.appearsAt && !firedEvents.current.has(key)) {
          firedEvents.current.add(key);
          setActivePrediction(pred);
          setPredictionTimer(pred.durationSec);
          setUserPick(null);
          setPredictionResolved(false);
          addFeed({
            type: 'prediction',
            text: `New prediction: "${pred.question}"`,
            emoji: '🔮',
            detail: `+${pred.pointReward} pts if correct`,
          });
        }
        // Resolve prediction after duration
        const resolveKey = `pred-resolve-${pred.id}`;
        if (t === pred.appearsAt + pred.durationSec + 3 && !firedEvents.current.has(resolveKey)) {
          firedEvents.current.add(resolveKey);
          setPredictionResolved(true);
          setTimeout(() => {
            setActivePrediction(null);
            setPredictionResolved(false);
          }, 3000);
        }
      });

      // Fire ads
      AD_CATALOG.forEach(ad => {
        const key = `ad-${ad.id}`;
        if (t === ad.appearsAt && !firedEvents.current.has(key)) {
          firedEvents.current.add(key);
          setActiveAd(ad);
          setLastAd(ad);
          setAdTimer(ad.durationSec);
          addFeed({
            type: 'ad',
            text: `${ad.brand} — "${ad.tagline}"`,
            emoji: ad.emoji,
            detail: `$${ad.cpm} CPM · ${ad.targetSegment} · PoD ✅`,
          });
        }
      });

      // Fire chat messages
      CHAT_MESSAGES.forEach(msg => {
        const key = `chat-${msg.at}-${msg.user}`;
        if (t === msg.at && !firedEvents.current.has(key)) {
          firedEvents.current.add(key);
          setChat(prev => [...prev, msg].slice(-30));
          if (msg.type === 'fan') {
            addFeed({ type: 'chat', text: `${msg.user}: ${msg.text}`, emoji: msg.avatar });
          }
        }
      });

    }, 1000);

    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handlePredictionPick = useCallback((index: number) => {
    if (userPick !== null || predictionResolved) return;
    setUserPick(index);
    if (activePrediction && index === activePrediction.correctIndex) {
      awardPoints(activePrediction.pointReward, `Correct! ${activePrediction.question}`);
    }
  }, [userPick, predictionResolved, activePrediction, awardPoints]);

  const handleBingoClick = useCallback((index: number) => {
    setBingoBoard(prev => {
      if (prev[index].free || prev[index].marked) return prev;
      const next = prev.map((c, i) => i === index ? { ...c, marked: true } : c);
      // Check lines
      const lines = [
        [0,1,2,3,4],[5,6,7,8,9],[10,11,12,13,14],[15,16,17,18,19],[20,21,22,23,24],
        [0,5,10,15,20],[1,6,11,16,21],[2,7,12,17,22],[3,8,13,18,23],[4,9,14,19,24],
        [0,6,12,18,24],[4,8,12,16,20],
      ];
      const completed = lines.filter(l => l.every(i => next[i].marked || next[i].free)).length;
      if (completed > bingoLines) {
        awardPoints(completed === 1 ? 500 : 250, `BINGO LINE ${completed}!`);
      }
      setBingoLines(completed);
      return next;
    });
    awardPoints(25, 'Bingo cell marked');
  }, [bingoLines, awardPoints]);

  return {
    elapsed, homeScore, awayScore, quarter, clock,
    activePrediction, predictionTimer, userPick, predictionResolved,
    handlePredictionPick,
    activeAd, lastAd, adTimer,
    points, flyPoints,
    feed, chat,
    bingoBoard, bingoLines, handleBingoClick,
  };
}
