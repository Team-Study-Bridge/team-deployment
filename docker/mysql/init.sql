-- 데이터베이스 생성: 각 기능별로 분리하여 관리하기 위해 3개의 데이터베이스를 생성한다.
CREATE DATABASE IF NOT EXISTS `lecture`;   -- 강의 관련 데이터베이스 (강의 정보 및 강의 콘텐츠 저장)
CREATE DATABASE IF NOT EXISTS `order`;     -- 결제 관련 데이터베이스 (결제 기록 저장)
CREATE DATABASE IF NOT EXISTS `user`;      -- 사용자 관련 데이터베이스 (사용자 정보 및 강사 정보 저장)
CREATE DATABASE IF NOT EXISTS `notitable`;

-- 사용 데이터베이스 설정: 사용자 관련 테이블을 'user' 데이터베이스에 생성한다.
USE `user`;

-- 1. users 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,                   
    email VARCHAR(255) NOT NULL UNIQUE,                   
    password VARCHAR(255) NULL,                           
    nickname VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NULL,   
    role ENUM('STUDENT', 'INSTRUCTOR', 'ADMIN') NOT NULL DEFAULT 'STUDENT',
    provider ENUM('LOCAL', 'GOOGLE', 'NAVER', 'KAKAO') NOT NULL DEFAULT 'LOCAL',  
    provider_id VARCHAR(255) NULL,                       
    profile_image VARCHAR(255) NULL,                    
    status ENUM('ACTIVE', 'INACTIVE', 'BANNED') NOT NULL DEFAULT 'ACTIVE',  
    status_changed_at TIMESTAMP NULL DEFAULT NULL, 
    last_login_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. teachers 테이블 생성 (외래키 포함)
CREATE TABLE IF NOT EXISTS teachers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,               
    user_id BIGINT NOT NULL,                            
    name VARCHAR(100) NOT NULL,                         -- 신청 시 이름
    bio TEXT NOT NULL,                                  -- 자기소개
    category VARCHAR(50) NOT NULL,                      -- 카테고리 (프론트에서 선택된 값 그대로)
    profile_image VARCHAR(255) DEFAULT NULL,            -- S3 URL
    resume_file VARCHAR(255) DEFAULT NULL,              -- S3 URL
    rating FLOAT DEFAULT 0.0,                           
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     
    teacher_status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',

    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3. email_verification 테이블 생성
CREATE TABLE IF NOT EXISTS email_verification (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_email (email)  -- 이메일 당 하나의 코드만 존재하도록 설정
);

USE `lecture`;

-- 4. product 테이블 생성 (강의 정보 저장)
CREATE TABLE IF NOT EXISTS product (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,         -- 강의 고유 ID (Primary Key)
    instructor_id BIGINT NOT NULL,                -- 강사 ID (teachers 테이블의 id 참조)
    title VARCHAR(255) NOT NULL,                  -- 강의 제목
    description TEXT NOT NULL,                    -- 강의 설명
    price INT NOT NULL,                           -- 강의 가격
    category VARCHAR(100) NOT NULL,               -- 강의 카테고리 (예: 프로그래밍, 디자인 등)
    thumbnail_url VARCHAR(1024) DEFAULT NULL,     -- 강의 썸네일 이미지 URL
    video_url VARCHAR(1024),                      -- 강의 동영상 URL
    instructor_name VARCHAR(255) NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 강의 등록일
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- 마지막 수정일 (자동 업데이트)
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING'  -- 강의 승인 상태
);

-- 5. product_contents 테이블 생성 (강의 내용 저장)
CREATE TABLE IF NOT EXISTS product_contents (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,                    -- 강의 콘텐츠 고유 ID (Primary Key)
    product_id BIGINT NOT NULL,                              -- 강의 ID (product 테이블의 id 참조)
    section INT NOT NULL,                                    -- 강의 섹션 번호 (순서 지정)
    title VARCHAR(255) NOT NULL,                             -- 강의 섹션 제목
    content TEXT,                                            -- 강의 내용 (텍스트 혹은 Markdown 형식)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,          -- 콘텐츠 등록일
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  -- 콘텐츠 수정일 (자동 업데이트)
);

-- 사용 데이터베이스 설정: 결제 관련 테이블을 'order' 데이터베이스에 생성한다.
USE `order`;

-- 6. purchase 테이블 생성 (결제 기록 저장)
CREATE TABLE IF NOT EXISTS purchase (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,                             -- 결제 고유 ID (Primary Key)
    user_id BIGINT NOT NULL,                                          -- 결제를 한 사용자 ID (user.users 테이블의 id 참조)
    product_id BIGINT NOT NULL,                                       -- 구매한 강의 ID (lectures.product 테이블의 id 참조)
    merchant_uid VARCHAR(50) UNIQUE NOT NULL,                         -- 주문 고유 번호: 결제 완료 이후 결제 기록 조회나 위변조 대사 작업 시 사용
    imp_uid VARCHAR(255),                                             -- 포트원 결제 고유 번호 (검증용)
    product_price INT NOT NULL ,                                      -- 구매한 강의 가격
    paid_amount INT NOT NULL ,                                        -- 결제된 금액
    payment_method VARCHAR(50) NOT NULL,                              -- 결제 방식 (예: CREDIT_CARD, PAYPAL, KAKAO_PAY 등)
    status ENUM('PENDING', 'COMPLETED', 'FAILED', 'CANCELED', 'ROLLBACK_REQUESTED', 'REFUNDED'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                   -- 결제 일시
    is_verified BOOLEAN DEFAULT FALSE,
    reason VARCHAR(255) NULL COMMENT '상태 변경 이유 (검증 시도 실패, 롤백 시도 실패 등)',
    FOREIGN KEY (user_id) REFERENCES user.users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES lecture.product(id)
);

-- 7. rollback_failure 테이블 생성 (롤백 실패 저장)
CREATE TABLE IF NOT EXISTS rollback_failure (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    purchase_id BIGINT NOT NULL,                    -- purchase table의 PK인 id 값이지만 따로 관리하기 위해 fk 사용 x
    imp_uid VARCHAR(255) NOT NULL,
    amount INT NOT NULL,                            -- 결제된 금액
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. 사용자 취소 실패를 저장하는 테이블
CREATE TABLE IF NOT EXISTS cancel_failure (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    purchase_id BIGINT NOT NULL,             -- purchase 테이블의 PK, fk 없이 저장
    imp_uid VARCHAR(255) NOT NULL,           -- PortOne imp_uid
    amount INT NOT NULL,                     -- 결제된 금액
    reason TEXT,                             -- 실패 이유 (ex. DB save 실패 메시지)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

USE `notitable`;

CREATE TABLE IF NOT EXISTS notification (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    channel ENUM('SMS', 'ALIMTALK', 'EMAIL', 'PUSH') NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    status ENUM('PENDING', 'SENT', 'FAILED') DEFAULT 'PENDING',
    error_message TEXT,
    scheduled_at DATETIME,
    sent_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_push_token (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    fcm_token TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_contact (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS kakao_template (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    template_code VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_email (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL,
    is_verified BOOLEAN DEFAULT TRUE,
    is_subscribed BOOLEAN DEFAULT TRUE,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);



USE `user`;

-- users 테이블 더미 데이터 (영문 닉네임으로 변경)
INSERT INTO users (email, password, nickname, phone_number, role, provider, provider_id, status, status_changed_at, last_login_at)
VALUES
('admin@example.com', '$2a$10$nSbmA8.arG6BzMADtkA2bOQW9oYNXSZ7NXeEBGiLH4gCa3HnK585a', 'admin', '010-0000-0000', 'ADMIN', 'LOCAL', NULL, 'ACTIVE', NOW(), NOW()),
('student@example.com', '$2a$10$nSbmA8.arG6BzMADtkA2bOQW9oYNXSZ7NXeEBGiLH4gCa3HnK585a', 'student_user', '010-1111-1111', 'STUDENT', 'LOCAL', NULL, 'ACTIVE', NOW(), NOW()),
('instructor@example.com', '$2a$10$nSbmA8.arG6BzMADtkA2bOQW9oYNXSZ7NXeEBGiLH4gCa3HnK585a', 'instructor_user', '010-2222-2222', 'INSTRUCTOR', 'LOCAL', NULL, 'ACTIVE', NOW(), NOW());

-- teachers 테이블 더미 데이터 (영문 이름 및 소개)
INSERT INTO teachers (user_id, name, bio, category, rating, teacher_status)
VALUES
(3, 'John Doe', 'Hello, I am a backend instructor with industry experience.', 'BACKEND', 4.8, 'APPROVED');

USE `lecture`;

-- 강의 데이터 삽입 (instructor_id = 3)
INSERT INTO product (
    id,
    instructor_id,
    title,
    description,
    price,
    category,
    thumbnail_url,
    video_url,
    instructor_name,
    status
) VALUES (
    1,
    3,
    'Build Solid Frontend with TypeScript',
    'Type-safe and productive choice for frontend developers.',
    99000,
    'frontend',
    'https://aigongbu-lecture-files.s3.ap-northeast-2.amazonaws.com/thumbnails/thumbnail_1_2.png',
    'https://aigongbu-lecture-files.s3.ap-northeast-2.amazonaws.com/videos/lecture_1_2.mp4',
    'John Doe',
    'APPROVED'
);

-- 강의 콘텐츠 삽입
INSERT INTO product_contents (
    product_id,
    section,
    title,
    content
) VALUES (
    1,
    3,
    'What is TypeScript?',
    'This section explains the basic concepts and benefits of TypeScript.'
);
