# 1. 패치 버전 및 패치 날짜를 출력하는 쿼리 작성
# 출력 컬럼: `lolVersionHistory` 테이블에 있는 모든 컬럼
EXPLAIN
SELECT *
FROM lolVersionHistory;

# 2. 본인 계정 닉네임(혹은 'Hide on bush')에 대한 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 소환사 닉네임
EXPLAIN
SELECT id, name
FROM opSummoner
WHERE name = 'Hide on bush';

# 3. summonerId = 4460427인 플레이어가 플레이한 게임 정보를 10개만 출력하는 쿼리 작성
# 출력 컬럼: 게임id, 챔피언id, 포지션, 승패
EXPLAIN
SELECT gameId, championId, position, result
FROM p_opGameStats
WHERE summonerId = 4460427
LIMIT 10;

# 4. 자유랭크 랭킹 1~20위의 랭크 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 포인트(LP), 승리 수, 패배 수
EXPLAIN
SELECT summonerId, leaguePoints, wins, losses
FROM opSummonerLeague
WHERE queueType = 'RANKED_FLEX_SR'
AND tier = 'CHALLENGER'
AND `rank` = 1
ORDER BY leaguePoints DESC
LIMIT 20;

# 5. 솔로랭크 티어, 랭크별로 소환사 수 출력하는 쿼리 작성
# 출력 컬럼: 티어, 랭크, 유저 수(userCount)
# `tier` 컬럼은 단순 CHARACTER가 아니라 ordering이 된 특수한 데이터 타입입니다.
# 높은 티어(챌린저>그랜드마스터>...), 높은 랭크(1>2>3>4)가 위에 출력되게 하세요.
EXPLAIN
SELECT tier, `rank`, COUNT(*) AS userCount
FROM opSummonerLeague
WHERE queueType = 'RANKED_SOLO_5x5'
GROUP BY tier, `rank`
ORDER BY tier DESC, `rank`;

# 6. 솔로랭크 티어, 랭크별로 승급전 진행 중인 유저 수를 출력하는 쿼리 작성
# 출력 컬럼: 티어, 랭크, 유저 수(userCount)
# 높은 티어(챌린저>그랜드마스터>...), 높은 랭크(1>2>3>4)가 위에 출력되게 하세요.
# HAVING을 사용하는 쿼리, HAVING을 사용하지 않는 쿼리를 둘 다 작성하세요.

# 6-1: HAVING 사용
EXPLAIN
SELECT tier, `rank`, COUNT(seriesTarget) AS userCount
FROM opSummonerLeague
WHERE queueType = 'RANKED_SOLO_5x5'
AND leaguePoints = 100
GROUP BY tier, `rank`
HAVING userCount > 0
ORDER BY tier DESC, `rank`;
# 6-2: HAVING 사용 X
EXPLAIN
SELECT tier, `rank`, COUNT(*) AS userCount
FROM opSummonerLeague
WHERE queueType = 'RANKED_SOLO_5x5'
AND leaguePoints = 100
AND seriesTarget IS NOT NULL
GROUP BY tier, `rank`
ORDER BY tier DESC, `rank`;

# 7. 닉네임이 'Hide on'으로 시작하거나 'SKT T1'으로 시작하는 계정 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 소환사 닉네임
# 각 분류마다 10개씩만 출력하세요. 총 20개 (Hide on ## 10개 + SKT T1 ## 10개)
# SUBSTRING을 사용하지 말고 작성하세요.
EXPLAIN
(SELECT id, name
FROM opSummoner
WHERE name LIKE 'Hide on%'
LIMIT 10)
UNION
(SELECT id, name
FROM opSummoner
WHERE name LIKE 'SKT T1%'
LIMIT 10);

# 8. 솔로랭크 랭킹 1~10위의 랭크 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 티어, `rank`, LP, 판 수(gameCount), 승률(Winrate)
EXPLAIN
SELECT summonerId, name, tier, `rank`, leaguePoints, (wins+losses) AS gameCount, (wins/(wins+losses)) AS Winrate
FROM opSummonerLeague l
LEFT JOIN opSummoner s
ON l.summonerId = s.id
WHERE queueType = 'RANKED_SOLO_5x5'
AND tier = 'CHALLENGER'
AND `rank` = 1
ORDER BY leaguePoints DESC
LIMIT 10;

# 9. 8번 문제에 나온 10명의 광복절 연휴(2021년 8월 14일~2021년 8월 16일) 승률을 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 판 수(gameCount), 승률(Winrate)
# 다시하기 게임 제외합니다.
EXPLAIN
SELECT STRAIGHT_JOIN l.summonerId, name, COUNT(*) AS gameCount, COUNT(if(result = 'WIN',1,NULL))/COUNT(*) AS Winrate
FROM opSummonerLeague l
LEFT JOIN opSummoner s
ON l.summonerId = s.id
LEFT JOIN p_opGameStats p
ON l.summonerId = p.summonerId
WHERE queueType = 'RANKED_SOLO_5x5'
AND tier = 'CHALLENGER'
AND `rank` = 1
AND result != 'UNKNOWN'
AND createDate >= '2021-08-14'
AND createDate < '2021-08-17'
GROUP BY leaguePoints, l.summonerId
ORDER BY leaguePoints DESC
LIMIT 10;

# 10. 솔로 랭크 챌린저 300명에 대해 솔로랭크(420) 게임당 용 처치 수를 내림차순으로 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 게임당 용 처치 수(AvgDragonKills)
# 다시하기 게임 제외합니다.
EXPLAIN
SELECT l.summonerId, name, AVG(dragonKills) AS AvgDragonKills
FROM opSummonerLeague l
INNER JOIN opSummoner s
ON l.summonerId = s.id
INNER JOIN p_opGameStats p
ON l.summonerId = p.summonerId
INNER JOIN opGame o
ON p.gameId = o.gameId
INNER JOIN opGameTeam t
ON p.gameId = t.gameId
AND p.teamId = t.teamId
WHERE queueType = 'RANKED_SOLO_5x5'
AND tier = 'CHALLENGER'
AND `rank` = 1
AND subType = 420
AND result != 'UNKNOWN'
GROUP BY l.summonerId
ORDER BY AvgDragonKills DESC;

# 11. 마스터 이상 소환사가 포함된 솔로 랭크 게임에서 챔피언별로 밴된 횟수(banCount)를 출력하는 쿼리 작성
# 출력 컬럼: 챔피언id, 밴된 횟수(banCount)
# `p_opGameStats`의 `tierRank` 대신 opSummonerLeague의 `tier` 정보를 이용하세요.
# 다시하기 게임 제외합니다.
# banCount 내림차순으로 정렬하세요.
# Subquery를 사용하는 쿼리, 사용하지 않는 쿼리를 둘 다 작성하세요.

# 11-1: Subquery 사용
EXPLAIN
SELECT b.championId, COUNT(*) AS banCount
FROM opBannedChampion b
WHERE gameId IN (
    SELECT DISTINCT(p.gameId)
    FROM p_opGameStats p
    INNER JOIN opSummonerLeague l
    ON p.summonerId = l.summonerId
    INNER JOIN opGame o
    ON p.gameId = o.gameId
    WHERE subType = 420
    AND result != 'UNKNOWN'
    AND queueType = 'RANKED_SOLO_5x5'
    AND tier IN ('MASTER','GRANDMASTER','CHALLENGER')
    )
GROUP BY b.championId
ORDER BY banCount DESC;
# 11-2: Subquery 사용X
EXPLAIN
SELECT STRAIGHT_JOIN b.championId, COUNT(DISTINCT(b.gameId)) AS banCount
FROM opSummonerLeague l FORCE INDEX (ix_queueType_tier_rank_leaguePoints)
INNER JOIN p_opGameStats p
ON p.summonerId = l.summonerId
INNER JOIN opGame o
ON o.gameId = p.gameId
INNER JOIN opBannedChampion b
ON b.gameId = o.gameId
WHERE subType = 420
AND result != 'UNKNOWN'
AND queueType = 'RANKED_SOLO_5x5'
AND tier IN ('MASTER','GRANDMASTER','CHALLENGER')
GROUP BY b.championId
ORDER BY banCount DESC;

# 12. 2021년 8월 18일 솔로 랭크 게임에서 각 챔피언의 픽 횟수, 승률, KDA 출력
# 출력 컬럼: 챔피언id, 픽된 횟수(pickCount), KDA
# 다시하기 게임 제외합니다.
# pickCount 내림차순으로 정렬하세요.
# KDA = (KILL + ASSIST) / DEATH
EXPLAIN
SELECT p.championId, COUNT(*) AS pickCount, sum(championsKilled + assists)/sum(numDeaths) AS KDA
FROM p_opGameStats p
INNER JOIN opGame o
ON p.gameId = o.gameId
WHERE o.createDate >= '2021-08-18'
AND o.createDate < '2021-08-19'
AND result != 'UNKNOWN'
AND subType = 420
GROUP BY p.championId
ORDER BY pickCount DESC;