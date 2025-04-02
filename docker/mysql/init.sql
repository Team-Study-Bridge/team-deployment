-- 데이터베이스 생성: 각 기능별로 분리하여 관리하기 위해 3개의 데이터베이스를 생성한다.
CREATE DATABASE IF NOT EXISTS `courses`;   -- 강의 관련 데이터베이스 (강의 정보 및 강의 콘텐츠 저장)
CREATE DATABASE IF NOT EXISTS `order`;     -- 결제 관련 데이터베이스 (결제 기록 저장)
CREATE DATABASE IF NOT EXISTS `user`;      -- 사용자 관련 데이터베이스 (사용자 정보 및 강사 정보 저장)

-- 사용 데이터베이스 설정: 사용자 관련 테이블을 'user' 데이터베이스에 생성한다.
USE `user`;

-- 1. users 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,                   
    email VARCHAR(255) NOT NULL UNIQUE,                   
    password VARCHAR(255) NULL,                           
    nickname VARCHAR(100) NOT NULL,                      
    role ENUM('STUDENT', 'INSTRUCTOR', 'ADMIN') NOT NULL DEFAULT 'STUDENT',
    provider ENUM('LOCAL', 'GOOGLE', 'NAVER', 'KAKAO') DEFAULT 'LOCAL',  
    provider_id VARCHAR(255) NULL,                       
    profile_image VARCHAR(255) NULL,                    
    status ENUM('ACTIVE', 'INACTIVE', 'BANNED') DEFAULT 'ACTIVE',  
    last_login TIMESTAMP NULL,                          
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE                   -- 이메일 인증 여부 추가
);

-- 2. teachers 테이블 생성 (외래키 포함)
CREATE TABLE IF NOT EXISTS teachers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,               
    user_id BIGINT NOT NULL,                           
    bio TEXT NULL,                                      
    profile_image VARCHAR(255) DEFAULT NULL,           
    rating FLOAT DEFAULT 0.0,                          
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',  
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

-- 사용 데이터베이스 설정: 강의 관련 테이블을 'courses' 데이터베이스에 생성한다.
USE `courses`;

-- 4. product 테이블 생성 (강의 정보 저장)
CREATE TABLE IF NOT EXISTS product (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    instructor_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    thumbnail_url VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    FOREIGN KEY (instructor_id) REFERENCES user.teachers(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- 5. product_contents 테이블 생성 (강의 내용 저장)
CREATE TABLE IF NOT EXISTS product_contents (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_id BIGINT NOT NULL,
    section INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    video_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES product(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- 사용 데이터베이스 설정: 결제 관련 테이블을 'order' 데이터베이스에 생성한다.
USE `order`;

-- 6. purchase 테이블 생성 (결제 기록 저장)
CREATE TABLE IF NOT EXISTS purchase (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    status ENUM('PENDING', 'COMPLETED', 'FAILED') DEFAULT 'PENDING',
    payment_method VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user.users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES courses.product(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);
