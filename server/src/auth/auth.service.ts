import { Injectable, UnauthorizedException, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { OAuth2Client } from 'google-auth-library';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  private readonly googleClient: OAuth2Client;

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {
    this.googleClient = new OAuth2Client(
      this.configService.get<string>('GOOGLE_CLIENT_ID'),
    );
  }

  async googleLogin(googleAuthDto: GoogleAuthDto) {
    const { idToken } = googleAuthDto;

    let payload;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.configService.get<string>('GOOGLE_CLIENT_ID'),
      });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Invalid Google ID token');
    }

    if (!payload || !payload.email) {
      throw new BadRequestException('Google account has no email');
    }

    const googleId = payload.sub;
    const email = payload.email;
    const name = payload.name ?? email.split('@')[0];
    const avatarUrl = payload.picture ?? null;

    // Check if user exists by googleId first
    let user = await this.usersService.findByGoogleId(googleId);
    if (user) {
      // Existing Google user — login
      const tokens = await this.generateTokens(user.id, user.email);
      await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);
      return {
        user: { id: user.id, email: user.email, name: user.name, avatarUrl: user.avatarUrl },
        ...tokens,
      };
    }

    // Check if email is already registered (account linking)
    user = await this.usersService.findByEmail(email);
    if (user) {
      // Link Google to existing account
      await this.usersService.linkGoogleAccount(user.id, googleId, avatarUrl);
      const tokens = await this.generateTokens(user.id, user.email);
      await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);
      return {
        user: { id: user.id, email: user.email, name: user.name, avatarUrl: user.avatarUrl },
        ...tokens,
      };
    }

    // New user from Google
    user = await this.usersService.createFromGoogle({
      email,
      name,
      googleId,
      avatarUrl,
    });
    const tokens = await this.generateTokens(user.id, user.email);
    await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);
    return {
      user: { id: user.id, email: user.email, name: user.name, avatarUrl: user.avatarUrl },
      ...tokens,
    };
  }

  async register(registerDto: RegisterDto) {
    const user = await this.usersService.create(registerDto);
    const tokens = await this.generateTokens(user.id, user.email);
    await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
      ...tokens,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user) {
      throw new NotFoundException('Email not registered');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException('This account uses Google sign-in. Please sign in with Google.');
    }
    const isPasswordValid = await bcrypt.compare(loginDto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid password');
    }

    const tokens = await this.generateTokens(user.id, user.email);
    await this.usersService.updateRefreshToken(user.id, tokens.refreshToken);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
      ...tokens,
    };
  }

  async refresh(userId: string, refreshToken: string) {
    const user = await this.usersService.findById(userId);
    if (!user || !user.refreshTokenHash) {
      throw new UnauthorizedException('Access denied');
    }

    const isRefreshTokenValid = await bcrypt.compare(refreshToken, user.refreshTokenHash);
    if (!isRefreshTokenValid) {
      throw new UnauthorizedException('Access denied');
    }

    // Generate new access token
    const accessToken = await this.jwtService.signAsync(
      { sub: user.id, email: user.email },
      {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: '15m',
      },
    );

    return { accessToken };
  }

  async logout(userId: string) {
    await this.usersService.updateRefreshToken(userId, null);
  }

  private async generateTokens(userId: string, email: string) {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(
        { sub: userId, email },
        {
          secret: this.configService.get<string>('JWT_SECRET'),
          expiresIn: '15m',
        },
      ),
      this.jwtService.signAsync(
        { sub: userId, email },
        {
          secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
          expiresIn: '7d',
        },
      ),
    ]);

    return { accessToken, refreshToken };
  }

  // Helper method to verify refresh token and return payload
  async verifyRefreshToken(token: string) {
    try {
      return await this.jwtService.verifyAsync(token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch (e) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}
