package com.ipt.web.service;

import com.ipt.web.model.UnconfirmedUser;

public interface UserService {
    void save(UnconfirmedUser user);

    UnconfirmedUser findByUsername(String user);
}
