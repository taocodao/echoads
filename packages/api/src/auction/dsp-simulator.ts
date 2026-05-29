export interface BidRequest {
  slotId: string;
  floorCpm: number;
  channel: string;
}

export interface BidResponse {
  id: string;
  seatbid: Array<{
    bid: Array<{
      id: string;
      price: number;
      adid: string;
      crid: string;
      advertiserId: string;
    }>;
  }>;
}

export function simulateDSPBids(req: BidRequest): BidResponse[] {
  const responses: BidResponse[] = [];
  
  // DSP 1: Sports Premium (bids 1.5x - 2.0x floor)
  const isSports = req.channel.includes("sports") || req.channel.includes("live");
  if (isSports) {
    const multiplier = 1.5 + Math.random() * 0.5;
    responses.push({
      id: "dsp-1-sports",
      seatbid: [{
        bid: [{
          id: `bid-${Date.now()}-1`,
          price: Number((req.floorCpm * multiplier).toFixed(2)),
          adid: "spot-clarity-001",
          crid: "creative-001",
          advertiserId: "0xDemo000000000000000000000000000000000001",
        }]
      }]
    });
  }

  // DSP 2: General (bids 1.0x - 1.5x floor)
  const multiplier2 = 1.0 + Math.random() * 0.5;
  responses.push({
    id: "dsp-2-general",
    seatbid: [{
      bid: [{
        id: `bid-${Date.now()}-2`,
        price: Number((req.floorCpm * multiplier2).toFixed(2)),
        adid: "spot-clarity-002",
        crid: "creative-002",
        advertiserId: "0xDemo000000000000000000000000000000000002",
      }]
    }]
  });

  return responses;
}
