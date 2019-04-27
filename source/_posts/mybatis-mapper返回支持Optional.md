---
title: mybatis mapper返回支持Optional
date: 2019-04-19 15:05:05
tags:
- mybatis
- Optional
---
> java8发布以来，带来了很多的新特性，其中`Optional`则旨在减少`NullPointException`，避免if条件的判空,提升了代码的美观度.然而2014年发布java8的很久之后，`mabatis`都没有很好的支持mapper中返回`Optional`。终于在`mybatis-3.5.0`(2019-01-21)中对该功能进行的支持！！！

#### 一. mybatis-3.5.0
1. [mybatis-3.5.0更新记录](https://github.com/mybatis/mybatis-3/releases)
```
Enhancements:
Support java.util.Optional as return type of mapper method. #799
...
```

#### 二. 体验
> springboot + mybatis
1. pom.xml
```xml
<modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.1.4.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.justme</groupId>
    <artifactId>mybatis-demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>mybatis-demo</name>
    <description>Demo project for Spring Boot</description>
    <properties>
        <java.version>1.8</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
            <version>2.0.1</version>
        </dependency>
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.mybatis/mybatis-typehandlers-jsr310 -->
        <!--<dependency>-->
            <!--<groupId>org.mybatis</groupId>-->
            <!--<artifactId>mybatis-typehandlers-jsr310</artifactId>-->
            <!--<version>1.0.2</version>-->
        <!--</dependency>-->
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
```
2. mapper
```java
@Mapper
public interface CarApprovalMapper {

    @Select("select * from car_approval where car_identify = #{carIdentify}")
    Optional<CarApproval> getByCarIdentity(String carIdentify);

    @Insert("insert into car_approval(car_identify, relation_no, user_id, user_name, remarks, create_time) values(#{carIdentify}, #{relationNo}, #{userId}, #{userName}, #{remarks}, #{createTime})")
    int insert(CarApproval carApproval);

}
```

3. 测试
```java
/**
 * @date 2019/4/19 14:44
 */
@RunWith(SpringRunner.class)
@SpringBootTest
public class CarApprovalMapperTest {

    @Autowired
    private CarApprovalMapper carApprovalMapper;

    @Test
    public void getByCarIdentityTest() {
        Optional<CarApproval> car = carApprovalMapper.getByCarIdentity("");
        Assert.assertEquals(car, Optional.empty());
    }

    @Test
    public void insertTest() {
        CarApproval carApproval = new CarApproval();
        carApproval.setCarIdentify("dsfsdfsfdsfsdf");
        carApproval.setUserId(111);
        carApproval.setUserName("jack");
        carApproval.setCreateTime(LocalDateTime.now());
        carApprovalMapper.insert(carApproval);
    }

}
大家可以自己动手，跑一下测试，不过多演示了。

```
#### 三. 总结
经过测试，发现mybatis终于可以很爽的支持`mapper`的`Optional`的返回了，一起来体验`Optional`带来优雅便利吧！
