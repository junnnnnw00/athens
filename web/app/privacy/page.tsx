export const metadata = {
  title: "개인정보처리방침 — Athens",
  description: "Athens 앱의 개인정보 수집 및 이용에 관한 안내",
};

const sectionStyle: React.CSSProperties = {
  marginTop: 32,
};

const h2Style: React.CSSProperties = {
  fontSize: 18,
  fontWeight: 600,
  marginBottom: 8,
};

const pStyle: React.CSSProperties = {
  fontSize: 15,
  lineHeight: 1.7,
  opacity: 0.85,
};

const liStyle: React.CSSProperties = {
  fontSize: 15,
  lineHeight: 1.7,
  opacity: 0.85,
  marginBottom: 4,
};

export default function PrivacyPolicy() {
  return (
    <main
      style={{
        width: "100%",
        maxWidth: 680,
        margin: "0 auto",
        padding: "88px 24px 96px",
      }}
    >
      <h1 style={{ fontSize: 28, fontWeight: 700 }}>개인정보처리방침</h1>
      <p style={{ ...pStyle, marginTop: 8 }}>최종 업데이트: 2026년 6월 3일</p>

      <p style={{ ...pStyle, marginTop: 24 }}>
        Athens(이하 &ldquo;서비스&rdquo;)는 이용자의 개인정보를 중요하게 생각하며,
        관련 법령을 준수합니다. 본 방침은 서비스가 수집하는 정보와 그 이용 방식을
        설명합니다.
      </p>

      <section style={sectionStyle}>
        <h2 style={h2Style}>1. 수집하는 정보</h2>
        <ul>
          <li style={liStyle}>
            <strong>계정 정보:</strong> 회원가입 시 이메일 주소(Supabase Auth를
            통해 처리).
          </li>
          <li style={liStyle}>
            <strong>음악 평가 데이터:</strong> 이용자가 앱 내에서 생성한 곡 평가,
            랭킹, 선호 장르·무드 정보.
          </li>
          <li style={liStyle}>
            <strong>Last.fm 연동 정보(선택):</strong> 이용자가 직접 연결한 경우에
            한해 Last.fm 사용자명 및 최근 청취 기록.
          </li>
          <li style={liStyle}>
            <strong>프로필 정보(선택):</strong> 공개 프로필에 사용되는 핸들 및
            표시 이름.
          </li>
        </ul>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>2. 정보의 이용 목적</h2>
        <ul>
          <li style={liStyle}>서비스 제공 및 계정 인증</li>
          <li style={liStyle}>개인 음악 랭킹 및 취향 분석 제공</li>
          <li style={liStyle}>기기 간 데이터 동기화</li>
          <li style={liStyle}>이용자가 선택한 경우 공개 프로필 표시</li>
        </ul>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>3. 제3자 서비스</h2>
        <p style={pStyle}>
          서비스는 다음의 외부 서비스를 이용합니다: Supabase(인증·데이터 저장),
          Last.fm 및 MusicBrainz(음악 메타데이터). 각 서비스는 자체 개인정보
          처리방침을 따릅니다. 서비스는 이용자 데이터를 광고 목적으로 제3자에게
          판매하지 않습니다.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>4. 데이터 보관 및 삭제</h2>
        <p style={pStyle}>
          이용자 데이터는 계정이 유지되는 동안 보관됩니다. 계정 및 관련 데이터의 영구 삭제를 원하시는 경우,
          {" "}
          <a href="/delete-account" style={{ color: "inherit", textDecoration: "underline" }}>
            계정 및 데이터 삭제 요청 페이지
          </a>
          를 통해 신청하시거나 아래 이메일로 요청해 주시면 지체 없이 관련 데이터를 파기합니다.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>5. 보안</h2>
        <p style={pStyle}>
          모든 통신은 암호화(HTTPS)되며, 인증 토큰은 기기 보안 저장소에 보관됩니다.
          API 비밀키는 서버 측 엣지 함수에만 존재하며 앱에 포함되지 않습니다.
        </p>
      </section>

      <section style={sectionStyle}>
        <h2 style={h2Style}>6. 문의</h2>
        <p style={pStyle}>
          개인정보 관련 문의:{" "}
          <a href="mailto:godjunwoo2006@gmail.com" style={{ color: "inherit" }}>
            godjunwoo2006@gmail.com
          </a>
        </p>
      </section>
    </main>
  );
}
