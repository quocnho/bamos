// ============================================================================
// mascot/models.js — Định nghĩa Vector SVG của 4 Thú cưng linh vật
// ============================================================================

export const MASCOT_MODELS = {
    // 1. Chú cún con BamAI (Puppy)
    puppy: `
    <svg id="puppy-svg" viewBox="0 0 220 220" width="170" height="170">
        <defs>
            <radialGradient id="grad3DFace" cx="40%" cy="35%" r="65%">
                <stop offset="0%" stop-color="#FFEAA7" />
                <stop offset="50%" stop-color="#FDCB6E" />
                <stop offset="85%" stop-color="#E17055" />
                <stop offset="100%" stop-color="#D63031" />
            </radialGradient>
            <radialGradient id="grad3DBody" cx="35%" cy="30%" r="70%">
                <stop offset="0%" stop-color="#FFEAA7" />
                <stop offset="60%" stop-color="#FDCB6E" />
                <stop offset="90%" stop-color="#E17055" />
                <stop offset="100%" stop-color="#C0392B" />
            </radialGradient>
            <linearGradient id="grad3DEar" x1="20%" y1="0%" x2="80%" y2="100%">
                <stop offset="0%" stop-color="#E17055" />
                <stop offset="60%" stop-color="#D63031" />
                <stop offset="100%" stop-color="#8E1A1A" />
            </linearGradient>
            <linearGradient id="grad3DEarInner" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#FFB8B8" />
                <stop offset="70%" stop-color="#FF7675" />
                <stop offset="100%" stop-color="#E84393" />
            </linearGradient>
            <radialGradient id="grad3DMuzzle" cx="50%" cy="35%" r="55%">
                <stop offset="0%" stop-color="#FFFFFF" />
                <stop offset="65%" stop-color="#FFFDF0" />
                <stop offset="100%" stop-color="#FEEAA0" />
            </radialGradient>
            <radialGradient id="grad3DIris" cx="45%" cy="40%" r="55%">
                <stop offset="0%" stop-color="#8B4513" />
                <stop offset="45%" stop-color="#5C2C16" />
                <stop offset="80%" stop-color="#2D150B" />
                <stop offset="100%" stop-color="#120703" />
            </radialGradient>
            <radialGradient id="grad3DBell" cx="35%" cy="30%" r="60%">
                <stop offset="0%" stop-color="#FFF9D2" />
                <stop offset="45%" stop-color="#F1C40F" />
                <stop offset="85%" stop-color="#D35400" />
                <stop offset="100%" stop-color="#7E3200" />
            </radialGradient>
        </defs>

        <ellipse cx="110" cy="190" rx="65" ry="14" fill="#000000" opacity="0.18" filter="blur(4px)" />

        <g class="tail-group" transform-origin="152 145">
            <path class="tail" d="M 152 148 C 175 142, 195 125, 188 108 C 182 94, 168 112, 158 132 Z" fill="url(#grad3DBody)" />
            <path d="M 188 108 C 185 102, 175 110, 172 118 C 178 116, 185 112, 188 108 Z" fill="#FFFDF0" opacity="0.9" />
        </g>

        <g class="body-group">
            <path d="M 72 135 C 70 165, 82 188, 110 188 C 138 188, 150 165, 148 135 C 146 115, 74 115, 72 135 Z" fill="url(#grad3DBody)" />
            <ellipse cx="110" cy="155" rx="26" ry="24" fill="#FFFDF0" opacity="0.92" />
        </g>

        <g class="legs-group">
            <ellipse class="paw paw-left" cx="80" cy="186" rx="14" ry="9" fill="url(#grad3DBody)" />
            <ellipse class="paw paw-right" cx="140" cy="186" rx="14" ry="9" fill="url(#grad3DBody)" />
            <circle cx="76" cy="187" r="2.5" fill="#FFFDF0" opacity="0.8" />
            <circle cx="84" cy="187" r="2.5" fill="#FFFDF0" opacity="0.8" />
            <circle cx="136" cy="187" r="2.5" fill="#FFFDF0" opacity="0.8" />
            <circle cx="144" cy="187" r="2.5" fill="#FFFDF0" opacity="0.8" />
        </g>

        <g class="collar-group">
            <path d="M 76 126 Q 110 138 144 126 Q 110 144 76 126 Z" fill="#E74C3C" />
            <circle cx="110" cy="138" r="8" fill="url(#grad3DBell)" stroke="#B7950B" stroke-width="0.8" />
            <circle cx="110" cy="139" r="2.2" fill="#5C2C16" />
        </g>

        <g class="head-group">
            <g class="ears-group">
                <g class="ear-left" transform-origin="60 48">
                    <path d="M 68 55 C 40 45, 20 85, 36 118 C 46 132, 65 115, 66 85 Z" fill="url(#grad3DEar)" />
                    <path d="M 62 62 C 44 58, 32 88, 44 112 C 50 120, 62 108, 62 85 Z" fill="url(#grad3DEarInner)" opacity="0.85" />
                </g>
                <g class="ear-right" transform-origin="160 48">
                    <path d="M 152 55 C 180 45, 200 85, 184 118 C 174 132, 155 115, 154 85 Z" fill="url(#grad3DEar)" />
                    <path d="M 158 62 C 176 58, 188 88, 176 112 C 170 120, 158 108, 158 85 Z" fill="url(#grad3DEarInner)" opacity="0.85" />
                </g>
            </g>

            <ellipse cx="110" cy="78" rx="48" ry="42" fill="url(#grad3DFace)" />
            <path d="M 103 40 Q 110 36 117 40 L 114 62 Q 110 65 106 62 Z" fill="#FFFFFF" opacity="0.85" />
            <ellipse cx="110" cy="88" rx="26" ry="19" fill="url(#grad3DMuzzle)" />

            <g class="eyes-group">
                <g class="eye-group-left">
                    <g class="eye-open">
                        <ellipse cx="88" cy="72" rx="10.5" ry="12.5" fill="url(#grad3DIris)" />
                        <circle class="pupil-left" cx="88" cy="72" r="7" fill="#0A0402" />
                        <circle cx="85" cy="68" r="3.6" fill="#FFFFFF" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 78 74 Q 88 82 98 74" stroke="#4A2511" stroke-width="3" stroke-linecap="round" fill="none" />
                    </g>
                </g>
                <g class="eye-group-right">
                    <g class="eye-open">
                        <ellipse cx="132" cy="72" rx="10.5" ry="12.5" fill="url(#grad3DIris)" />
                        <circle class="pupil-right" cx="132" cy="72" r="7" fill="#0A0402" />
                        <circle cx="129" cy="68" r="3.6" fill="#FFFFFF" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 122 74 Q 132 82 142 74" stroke="#4A2511" stroke-width="3" stroke-linecap="round" fill="none" />
                    </g>
                </g>
            </g>

            <path d="M 103 82 Q 110 78 117 82 Q 110 93 103 82 Z" fill="#2D150B" />
            <g class="mouth-group">
                <path class="mouth-line" d="M 102 90 Q 110 95 118 90" stroke="#5C2C16" stroke-width="2.2" fill="none" stroke-linecap="round" />
                <path class="tongue" d="M 106 92 C 106 102, 114 102, 114 92 Z" fill="#FF7675" />
            </g>
            <ellipse cx="70" cy="82" rx="7.5" ry="5.5" fill="#FF7675" opacity="0.5" />
            <ellipse cx="150" cy="82" rx="7.5" ry="5.5" fill="#FF7675" opacity="0.5" />
        </g>
    </svg>`,

    // 2. Mèo con Tinh Nghịch (Cat)
    cat: `
    <svg id="puppy-svg" viewBox="0 0 220 220" width="170" height="170">
        <defs>
            <radialGradient id="gradCatFace" cx="45%" cy="40%" r="65%">
                <stop offset="0%" stop-color="#F8FAFC" />
                <stop offset="60%" stop-color="#E2E8F0" />
                <stop offset="100%" stop-color="#94A3B8" />
            </radialGradient>
            <radialGradient id="gradCatEye" cx="45%" cy="35%" r="60%">
                <stop offset="0%" stop-color="#A7F3D0" />
                <stop offset="50%" stop-color="#10B981" />
                <stop offset="100%" stop-color="#047857" />
            </radialGradient>
        </defs>

        <ellipse cx="110" cy="190" rx="60" ry="13" fill="#000000" opacity="0.16" filter="blur(4px)" />

        <g class="tail-group" transform-origin="150 150">
            <path class="tail" d="M 148 152 C 180 148, 198 120, 185 92 C 178 78, 166 88, 168 102 C 172 120, 155 140, 148 152 Z" fill="#94A3B8" />
            <circle cx="185" cy="92" r="7" fill="#F8FAFC" />
        </g>

        <g class="body-group">
            <path d="M 75 138 C 72 165, 82 188, 110 188 C 138 188, 148 165, 145 138 C 142 118, 78 118, 75 138 Z" fill="url(#gradCatFace)" />
            <ellipse cx="110" cy="160" rx="22" ry="20" fill="#FFFFFF" />
        </g>

        <g class="legs-group">
            <ellipse class="paw paw-left" cx="82" cy="186" rx="12" ry="8" fill="#FFFFFF" />
            <ellipse class="paw paw-right" cx="138" cy="186" rx="12" ry="8" fill="#FFFFFF" />
        </g>

        <g class="collar-group">
            <path d="M 80 128 Q 110 138 140 128 Q 110 142 80 128 Z" fill="#6366F1" />
            <circle cx="110" cy="136" r="6" fill="#FBBF24" stroke="#D97706" stroke-width="0.8" />
        </g>

        <g class="head-group">
            <g class="ears-group">
                <polygon points="65,72 50,26 92,54" fill="#64748B" />
                <polygon points="68,68 56,34 88,54" fill="#FCA5A5" opacity="0.9" />
                <polygon points="155,72 170,26 128,54" fill="#64748B" />
                <polygon points="152,68 164,34 132,54" fill="#FCA5A5" opacity="0.9" />
            </g>

            <ellipse cx="110" cy="80" rx="46" ry="38" fill="url(#gradCatFace)" />

            <!-- Râu mèo -->
            <line x1="55" y1="84" x2="30" y2="80" stroke="#94A3B8" stroke-width="1.8" stroke-linecap="round" />
            <line x1="55" y1="88" x2="32" y2="92" stroke="#94A3B8" stroke-width="1.8" stroke-linecap="round" />
            <line x1="165" y1="84" x2="190" y2="80" stroke="#94A3B8" stroke-width="1.8" stroke-linecap="round" />
            <line x1="165" y1="88" x2="188" y2="92" stroke="#94A3B8" stroke-width="1.8" stroke-linecap="round" />

            <g class="eyes-group">
                <g class="eye-group-left">
                    <g class="eye-open">
                        <ellipse cx="88" cy="74" rx="10" ry="12" fill="url(#gradCatEye)" />
                        <ellipse class="pupil-left" cx="88" cy="74" rx="3.5" ry="9" fill="#064E3B" />
                        <circle cx="85" cy="70" r="3" fill="#FFFFFF" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 78 76 Q 88 84 98 76" stroke="#475569" stroke-width="3" stroke-linecap="round" fill="none" />
                    </g>
                </g>
                <g class="eye-group-right">
                    <g class="eye-open">
                        <ellipse cx="132" cy="74" rx="10" ry="12" fill="url(#gradCatEye)" />
                        <ellipse class="pupil-right" cx="132" cy="74" rx="3.5" ry="9" fill="#064E3B" />
                        <circle cx="129" cy="70" r="3" fill="#FFFFFF" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 122 76 Q 132 84 142 76" stroke="#475569" stroke-width="3" stroke-linecap="round" fill="none" />
                    </g>
                </g>
            </g>

            <polygon points="106,85 114,85 110,90" fill="#F43F5E" />
            <path class="mouth-line" d="M 104 92 Q 110 96 116 92" stroke="#475569" stroke-width="2" fill="none" stroke-linecap="round" />
            <ellipse cx="72" cy="85" rx="6" ry="4" fill="#FDA4AF" opacity="0.6" />
            <ellipse cx="148" cy="85" rx="6" ry="4" fill="#FDA4AF" opacity="0.6" />
        </g>
    </svg>`,

    // 3. Thỏ Ngọc Trắng (Rabbit)
    rabbit: `
    <svg id="puppy-svg" viewBox="0 0 220 220" width="170" height="170">
        <defs>
            <radialGradient id="gradBunnyBody" cx="40%" cy="30%" r="70%">
                <stop offset="0%" stop-color="#FFFFFF" />
                <stop offset="70%" stop-color="#F1F5F9" />
                <stop offset="100%" stop-color="#CBD5E1" />
            </radialGradient>
        </defs>

        <ellipse cx="110" cy="190" rx="62" ry="13" fill="#000000" opacity="0.15" filter="blur(4px)" />

        <g class="tail-group">
            <circle class="tail" cx="152" cy="155" r="14" fill="#FFFFFF" stroke="#E2E8F0" stroke-width="1.5" />
        </g>

        <g class="body-group">
            <path d="M 72 136 C 70 166, 82 188, 110 188 C 138 188, 150 166, 148 136 C 146 115, 74 115, 72 136 Z" fill="url(#gradBunnyBody)" />
        </g>

        <g class="legs-group">
            <ellipse class="paw paw-left" cx="80" cy="186" rx="14" ry="9" fill="#FFFFFF" stroke="#E2E8F0" />
            <ellipse class="paw paw-right" cx="140" cy="186" rx="14" ry="9" fill="#FFFFFF" stroke="#E2E8F0" />
        </g>

        <g class="head-group">
            <g class="ears-group">
                <!-- Đôi tai thỏ dài -->
                <g class="ear-left" transform-origin="75 60">
                    <ellipse cx="75" cy="30" rx="13" ry="32" fill="url(#gradBunnyBody)" />
                    <ellipse cx="75" cy="32" rx="7" ry="24" fill="#FBCFE8" opacity="0.85" />
                </g>
                <g class="ear-right" transform-origin="145 60">
                    <ellipse cx="145" cy="30" rx="13" ry="32" fill="url(#gradBunnyBody)" />
                    <ellipse cx="145" cy="32" rx="7" ry="24" fill="#FBCFE8" opacity="0.85" />
                </g>
            </g>

            <ellipse cx="110" cy="86" rx="44" ry="38" fill="url(#gradBunnyBody)" />

            <g class="eyes-group">
                <g class="eye-group-left">
                    <g class="eye-open">
                        <ellipse cx="88" cy="80" rx="9" ry="11" fill="#BE185D" />
                        <circle class="pupil-left" cx="88" cy="80" r="6" fill="#831843" />
                        <circle cx="85" cy="76" r="3.2" fill="#FFFFFF" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 80 82 Q 88 88 96 82" stroke="#831843" stroke-width="2.6" stroke-linecap="round" fill="none" />
                    </g>
                </g>
                <g class="eye-group-right">
                    <g class="eye-open">
                        <ellipse cx="132" cy="80" rx="9" ry="11" fill="#BE185D" />
                        <circle class="pupil-right" cx="132" cy="80" r="6" fill="#831843" />
                        <circle cx="129" cy="76" r="3.2" fill="#FFFFFF" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 124 82 Q 132 88 140 82" stroke="#831843" stroke-width="2.6" stroke-linecap="round" fill="none" />
                    </g>
                </g>
            </g>

            <ellipse cx="110" cy="94" rx="4" ry="3" fill="#F472B6" />
            <path class="mouth-line" d="M 106 97 Q 110 102 114 97" stroke="#9D174D" stroke-width="1.8" fill="none" stroke-linecap="round" />
            <ellipse cx="74" cy="92" rx="8" ry="5" fill="#FBCFE8" opacity="0.8" />
            <ellipse cx="146" cy="92" rx="8" ry="5" fill="#FBCFE8" opacity="0.8" />
        </g>
    </svg>`,

    // 4. Ông Bụt Thông Thái (Wizard)
    wizard: `
    <svg id="puppy-svg" viewBox="0 0 220 220" width="170" height="170">
        <defs>
            <linearGradient id="gradRobe" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#3B82F6" />
                <stop offset="100%" stop-color="#1E3A8A" />
            </linearGradient>
            <radialGradient id="gradHalo" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stop-color="#FEF08A" stop-opacity="0.8" />
                <stop offset="100%" stop-color="#FACC15" stop-opacity="0" />
            </radialGradient>
        </defs>

        <circle cx="110" cy="80" r="58" fill="url(#gradHalo)" />
        <ellipse cx="110" cy="190" rx="55" ry="12" fill="#000000" opacity="0.18" filter="blur(4px)" />

        <g class="body-group">
            <path d="M 70 135 C 65 170, 75 190, 110 190 C 145 190, 155 170, 150 135 Z" fill="url(#gradRobe)" />
            <path d="M 110 135 L 110 190" stroke="#FDE047" stroke-width="2.5" />
        </g>

        <!-- Tay áo & Gậy thần -->
        <g class="legs-group">
            <ellipse cx="76" cy="155" rx="10" ry="16" fill="#2563EB" />
            <ellipse cx="144" cy="155" rx="10" ry="16" fill="#2563EB" />
            <line x1="150" y1="110" x2="155" y2="190" stroke="#78350F" stroke-width="3.5" stroke-linecap="round" />
            <circle cx="150" cy="108" r="6" fill="#38BDF8" stroke="#0284C7" stroke-width="1.2" />
        </g>

        <g class="head-group">
            <!-- Mũ pháp sư / Búi tóc tiên -->
            <polygon points="110,16 78,60 142,60" fill="#1D4ED8" />
            <ellipse cx="110" cy="60" rx="38" ry="6" fill="#FBBF24" />
            <polygon points="110,32 112,38 118,38 113,42 115,48 110,44 105,48 107,42 102,38 108,38" fill="#FEF08A" />

            <!-- Khuôn mặt hiền từ -->
            <ellipse cx="110" cy="78" rx="32" ry="26" fill="#FED7AA" />

            <g class="eyes-group">
                <g class="eye-group-left">
                    <g class="eye-open">
                        <circle cx="95" cy="76" r="4.5" fill="#1E293B" />
                        <circle cx="93.5" cy="74.5" r="1.5" fill="#FFFFFF" />
                        <!-- Lông mày trắng hiền hậu -->
                        <path d="M 86 68 Q 96 66 102 70" stroke="#FFFFFF" stroke-width="3.5" stroke-linecap="round" fill="none" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 88 77 Q 95 82 102 77" stroke="#1E293B" stroke-width="2.5" stroke-linecap="round" fill="none" />
                    </g>
                </g>
                <g class="eye-group-right">
                    <g class="eye-open">
                        <circle cx="125" cy="76" r="4.5" fill="#1E293B" />
                        <circle cx="123.5" cy="74.5" r="1.5" fill="#FFFFFF" />
                        <path d="M 124 70 Q 130 66 140 68" stroke="#FFFFFF" stroke-width="3.5" stroke-linecap="round" fill="none" />
                    </g>
                    <g class="eye-closed">
                        <path d="M 118 77 Q 125 82 132 77" stroke="#1E293B" stroke-width="2.5" stroke-linecap="round" fill="none" />
                    </g>
                </g>
            </g>

            <!-- Râu dài bạc phơ của Ông Bụt -->
            <path d="M 94 88 Q 110 88 126 88 C 132 115, 125 155, 110 165 C 95 155, 88 115, 94 88 Z" fill="#FFFFFF" stroke="#E2E8F0" stroke-width="1" />
            <path class="mouth-line" d="M 105 88 Q 110 92 115 88" stroke="#F43F5E" stroke-width="2" fill="none" stroke-linecap="round" />
            <ellipse cx="86" cy="82" rx="4" ry="3" fill="#FCA5A5" opacity="0.6" />
            <ellipse cx="134" cy="82" rx="4" ry="3" fill="#FCA5A5" opacity="0.6" />
        </g>
    </svg>`,
};
