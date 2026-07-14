import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DeepgramClient } from '@deepgram/sdk';

export interface DeepgramSession {
  socket: Awaited<ReturnType<DeepgramClient['listen']['v1']['connect']>>;
}

export interface DeepgramResultEvent {
  type: 'Results';
  channel?: {
    alternatives?: Array<{
      transcript?: string;
      confidence?: number;
    }>;
  };
  is_final?: boolean;
  speech_final?: boolean;
}

export interface DeepgramUtteranceEndEvent {
  type: 'UtteranceEnd';
  last_word_end: number;
}

export interface DeepgramSpeechStartedEvent {
  type: 'SpeechStarted';
  timestamp: number;
}

export interface DeepgramMetadataEvent {
  type: 'Metadata';
  transaction_key: string;
  request_id: string;
  sha256: string;
  created: string;
  duration: number;
  channels: number;
  models: string[];
}

export type DeepgramMessage = DeepgramResultEvent | DeepgramUtteranceEndEvent | DeepgramSpeechStartedEvent | DeepgramMetadataEvent;

export type TranscriptCallback = (text: string, isFinal: boolean) => void;
export type SpeechEndCallback = () => void;

@Injectable()
export class DeepgramService {
  private readonly logger = new Logger(DeepgramService.name);
  private readonly client: DeepgramClient;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('deepgram.apiKey') || '';
    const baseUrl = this.configService.get<string>('deepgram.baseUrl') || 'https://api.deepgram.com';
    if (!apiKey) {
      this.logger.warn('DEEPGRAM_API_KEY not configured');
    }
    this.client = new DeepgramClient({ apiKey, baseUrl });
  }

  async createSttSession(
    onTranscript: TranscriptCallback,
    onUtteranceEnd?: SpeechEndCallback,
  ): Promise<DeepgramSession> {
    const socket = await this.client.listen.v1.connect({
      model: 'nova-3',
      encoding: 'linear16',
      sample_rate: 16000,
      channels: 1,
      interim_results: 'true',
      smart_format: 'true',
      punctuate: 'true',
      utterance_end_ms: '1000',
      vad_events: 'true',
      endpointing: '2000',
    });

    socket.on('open', () => {
      this.logger.log('Deepgram STT connection opened');
    });

    socket.on('message', (data: any) => {
      try {
        switch (data.type) {
          case 'Results':
            const transcript = data.channel?.alternatives?.[0]?.transcript || '';
            const isFinal = data.is_final === true;
            if (transcript) {
              onTranscript(transcript, isFinal);
            }
            if (isFinal && data.speech_final) {
              this.logger.debug(`Final transcript: "${transcript}"`);
            }
            break;

          case 'UtteranceEnd':
            this.logger.debug('Utterance end detected');
            onUtteranceEnd?.();
            break;

          case 'SpeechStarted':
            this.logger.debug('Speech started');
            break;

          case 'Metadata':
            break;
        }
      } catch (err) {
        this.logger.error('Failed to process Deepgram message', err);
      }
    });

    socket.on('error', (err) => {
      this.logger.error('Deepgram STT error', err);
    });

    socket.on('close', () => {
      this.logger.log('Deepgram STT connection closed');
    });

    socket.connect();

    return { socket };
  }

  async synthesizeSpeech(text: string): Promise<Buffer> {
    const response = await this.client.speak.v1.audio.generate({
      text,
      model: 'aura-2-orion-en',
    });

    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer);
  }

  closeSession(session: DeepgramSession): void {
    try {
      session.socket.sendCloseStream({ type: 'CloseStream' });
    } catch (_) {}
    try {
      session.socket.close();
    } catch (_) {}
  }
}
