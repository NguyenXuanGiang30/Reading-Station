package com.tramdoc.controller;

import com.tramdoc.dto.request.CreateKeyTakeawayRequest;
import com.tramdoc.dto.request.ReorderTakeawaysRequest;
import com.tramdoc.dto.request.UpdateKeyTakeawayRequest;
import com.tramdoc.dto.response.KeyTakeawayResponse;
import com.tramdoc.service.KeyTakeawayService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class KeyTakeawayController {
    
    @Autowired
    private KeyTakeawayService keyTakeawayService;
    
    @GetMapping("/user-books/{userBookId}/takeaways")
    public ResponseEntity<List<KeyTakeawayResponse>> getKeyTakeaways(@PathVariable Long userBookId) {
        List<KeyTakeawayResponse> takeaways = keyTakeawayService.getKeyTakeaways(userBookId);
        return ResponseEntity.ok(takeaways);
    }
    
    @PostMapping("/user-books/{userBookId}/takeaways")
    public ResponseEntity<KeyTakeawayResponse> createKeyTakeaway(
            @PathVariable Long userBookId,
            @Valid @RequestBody CreateKeyTakeawayRequest request) {
        KeyTakeawayResponse takeaway = keyTakeawayService.createKeyTakeaway(userBookId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(takeaway);
    }
    
    @PutMapping("/takeaways/{takeawayId}")
    public ResponseEntity<KeyTakeawayResponse> updateKeyTakeaway(
            @PathVariable Long takeawayId,
            @Valid @RequestBody UpdateKeyTakeawayRequest request) {
        KeyTakeawayResponse takeaway = keyTakeawayService.updateKeyTakeaway(takeawayId, request);
        return ResponseEntity.ok(takeaway);
    }
    
    @DeleteMapping("/takeaways/{takeawayId}")
    public ResponseEntity<Void> deleteKeyTakeaway(@PathVariable Long takeawayId) {
        keyTakeawayService.deleteKeyTakeaway(takeawayId);
        return ResponseEntity.noContent().build();
    }
    
    @PutMapping("/takeaways/reorder")
    public ResponseEntity<List<KeyTakeawayResponse>> reorderTakeaways(
            @Valid @RequestBody ReorderTakeawaysRequest request) {
        List<KeyTakeawayResponse> takeaways = keyTakeawayService.reorderTakeaways(request.getTakeawayIds());
        return ResponseEntity.ok(takeaways);
    }
}
